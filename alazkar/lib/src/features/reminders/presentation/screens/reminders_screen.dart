import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/utils/arabic_number.dart';
import 'package:alazkar/src/core/utils/show_toast.dart';
import 'package:alazkar/src/features/reminders/data/models/place.dart';
import 'package:alazkar/src/features/reminders/data/models/prayer_method.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/domain/prayer_times_calculator.dart';
import 'package:alazkar/src/features/reminders/domain/reminder_planner.dart';
import 'package:alazkar/src/features/reminders/presentation/controller/reminders_cubit.dart';
import 'package:alazkar/src/features/reminders/presentation/screens/city_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String kNotificationsBlocked =
    'الإشعارات ممنوعة لهذا التطبيق، يمكنك السماح بها من إعدادات الهاتف';

const String kAppSettingsHint =
    'إن لم تصلك التذكيرات في وقتها، فاسمح للتطبيق بالعمل في الخلفية من إعدادات الهاتف';

const String kLocationNeeded =
    'يلزم تحديد الموقع لحساب أوقات الصلاة، فاختر مدينة';

const String kNoPlace = 'لم يحدد الموقع';

/// «بـ٥ دقائق» … «بـ١٥ دقيقة»: Arabic counts 3 to 10 take the plural.
String offsetLabel(int minutes) =>
    'بـ${ArabicNumbers.convert('$minutes')} ${minutes <= 10 ? 'دقائق' : 'دقيقة'}';

/// Opens the city list; true when the reader picked a city.
Future<bool> pickCity(BuildContext context) async {
  final cubit = context.read<RemindersCubit>();
  final place = await Navigator.of(context)
      .push<Place>(CityPickerScreen.route(cubit.cities));
  if (place == null) return false;
  await cubit.setPlace(place);
  return true;
}

Future<void> toggleReminder(
  BuildContext context,
  ReminderSlot slot,
  bool enabled,
) async {
  final cubit = context.read<RemindersCubit>();
  final result = await cubit.setEnabled(slot, enabled);
  if (result == ReminderToggle.notificationsRefused) {
    showToast(kNotificationsBlocked);
  }
  if (result != ReminderToggle.locationNeeded || !context.mounted) return;
  if (await pickCity(context)) await cubit.setEnabled(slot, true);
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    sl<RemindersCubit>().refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The reader may have just allowed notifications in the phone settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sl<RemindersCubit>().refreshPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<RemindersCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('التذكير'), centerTitle: true),
        body: BlocBuilder<RemindersCubit, RemindersState>(
          builder: (context, state) {
            final placeShown = state.locationNeeded ||
                state.locating ||
                state.settings.entries.any(
                  (entry) => entry.value.enabled && entry.key.needsPlace,
                );
            return ListView(
              padding: const EdgeInsets.all(15),
              children: [
                for (final slot in ReminderSlot.values)
                  _ReminderCard(
                    slot: slot,
                    title: state.titles[slot.titleId] ?? '',
                    setting: state.settings[slot]!,
                    today: state.today,
                  ),
                if (state.locationNeeded) const _Warning(text: kLocationNeeded),
                if (state.notificationsBlocked)
                  const _Warning(text: kNotificationsBlocked),
                if (placeShown) _PlaceCard(state: state),
                ListTile(
                  key: const ValueKey('reminder-app-settings'),
                  leading: const Icon(Icons.battery_saver),
                  title: const Text(kAppSettingsHint),
                  onTap: () =>
                      context.read<RemindersCubit>().platform.openAppSettings(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  final String text;

  const _Warning({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderSlot slot;
  final String title;
  final ReminderSetting setting;
  final PrayerDay? today;

  const _ReminderCard({
    required this.slot,
    required this.title,
    required this.setting,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            key: ValueKey('reminder-switch-${slot.name}'),
            title: Text(title),
            value: setting.enabled,
            onChanged: (value) => toggleReminder(context, slot, value),
          ),
          if (setting.kind.needsPrayerTimes)
            _prayerTile(context)
          else
            _clockTile(context),
        ],
      ),
    );
  }

  Widget _prayerTile(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final minute = reminderMinute(setting, today);
    return ListTile(
      enabled: setting.enabled,
      leading: const Icon(Icons.mosque_outlined),
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          if (slot.kinds.length > 1)
            SegmentedButton<ReminderKind>(
              key: ValueKey('reminder-kind-${slot.name}'),
              showSelectedIcon: false,
              segments: [
                for (final kind in slot.kinds)
                  ButtonSegment(value: kind, label: Text(kind.label)),
              ],
              selected: {setting.kind},
              onSelectionChanged: setting.enabled
                  ? (kinds) => cubit.setKind(slot, kinds.first)
                  : null,
            )
          else
            Text(setting.kind.label),
          DropdownButton<int>(
            key: ValueKey('reminder-offset-${slot.name}'),
            value: setting.offsetMinutes,
            items: [
              for (final minutes in kOffsetChoices)
                DropdownMenuItem(
                    value: minutes, child: Text(offsetLabel(minutes))),
            ],
            onChanged: setting.enabled
                ? (minutes) {
                    if (minutes != null) cubit.setOffset(slot, minutes);
                  }
                : null,
          ),
        ],
      ),
      subtitle: minute == null
          ? null
          : Text(
              'اليوم: ${MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
              )}',
              key: ValueKey('reminder-today-${slot.name}'),
            ),
    );
  }

  Widget _clockTile(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final time = TimeOfDay(
      hour: setting.minuteOfDay ~/ 60,
      minute: setting.minuteOfDay % 60,
    );
    return ListTile(
      enabled: setting.enabled,
      leading: const Icon(Icons.schedule),
      title: Text(MaterialLocalizations.of(context).formatTimeOfDay(time)),
      onTap: () async {
        // Typing is off: in Arabic the picker shows the hour in
        // Arabic-Indic digits and then rejects them as invalid.
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          initialEntryMode: TimePickerEntryMode.dialOnly,
        );
        if (picked == null) return;
        await cubit.setMinuteOfDay(slot, picked.hour * 60 + picked.minute);
      },
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final RemindersState state;

  const _PlaceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final place = state.place;
    final method = state.method;
    return Card(
      child: Column(
        children: [
          ListTile(
            key: const ValueKey('reminder-place'),
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('الموقع'),
            subtitle: Text(
              place == null ? kNoPlace : '${place.name}، ${place.countryName}',
            ),
          ),
          if (state.locating) const LinearProgressIndicator(),
          OverflowBar(
            alignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              TextButton.icon(
                key: const ValueKey('reminder-update-location'),
                icon: const Icon(Icons.my_location),
                label: const Text('تحديث موقعي'),
                onPressed: state.locating
                    ? null
                    : () async {
                        if (!await cubit.updateLocation() && context.mounted) {
                          await pickCity(context);
                        }
                      },
              ),
              TextButton.icon(
                key: const ValueKey('reminder-pick-city'),
                icon: const Icon(Icons.location_city),
                label: const Text('اختيار مدينة'),
                onPressed: () => pickCity(context),
              ),
            ],
          ),
          if (method != null)
            ListTile(
              title: const Text('طريقة الحساب'),
              subtitle: DropdownButton<PrayerMethod>(
                key: const ValueKey('reminder-method'),
                isExpanded: true,
                value: method,
                items: [
                  for (final choice in PrayerMethod.values)
                    DropdownMenuItem(value: choice, child: Text(choice.label)),
                ],
                onChanged: (choice) {
                  if (choice != null) cubit.setMethod(choice);
                },
              ),
            ),
          ListTile(
            title: const Text('مذهب العصر'),
            trailing: SegmentedButton<AsrMadhab>(
              key: const ValueKey('reminder-madhab'),
              showSelectedIcon: false,
              segments: [
                for (final madhab in AsrMadhab.values)
                  ButtonSegment(value: madhab, label: Text(madhab.label)),
              ],
              selected: {state.madhab},
              onSelectionChanged: (madhabs) => cubit.setMadhab(madhabs.first),
            ),
          ),
        ],
      ),
    );
  }
}
