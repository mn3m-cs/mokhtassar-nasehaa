import 'package:alazkar/src/core/di/dependency_injection.dart';
import 'package:alazkar/src/core/utils/show_toast.dart';
import 'package:alazkar/src/features/reminders/data/models/reminder.dart';
import 'package:alazkar/src/features/reminders/presentation/controller/reminders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String kNotificationsBlocked =
    'الإشعارات ممنوعة لهذا التطبيق، يمكنك السماح بها من إعدادات الهاتف';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<RemindersCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('التذكير'), centerTitle: true),
        body: BlocBuilder<RemindersCubit, RemindersState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(15),
              children: [
                for (final slot in ReminderSlot.values)
                  _ReminderCard(
                    slot: slot,
                    title: state.titles[slot.titleId] ?? '',
                    setting: state.settings[slot]!,
                  ),
                if (state.notificationsBlocked)
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(
                      kNotificationsBlocked,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderSlot slot;
  final String title;
  final ReminderSetting setting;

  const _ReminderCard({
    required this.slot,
    required this.title,
    required this.setting,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final time = TimeOfDay(
      hour: setting.minuteOfDay ~/ 60,
      minute: setting.minuteOfDay % 60,
    );
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            key: ValueKey('reminder-switch-${slot.name}'),
            title: Text(title),
            value: setting.enabled,
            onChanged: (value) async {
              final ok = await cubit.setEnabled(slot, value);
              if (!ok) showToast(kNotificationsBlocked);
            },
          ),
          ListTile(
            enabled: setting.enabled,
            leading: const Icon(Icons.schedule),
            title: Text(
              MaterialLocalizations.of(context).formatTimeOfDay(time),
            ),
            onTap: () async {
              // Typing is off: in Arabic the picker shows the hour in
              // Arabic-Indic digits and then rejects them as invalid.
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
                initialEntryMode: TimePickerEntryMode.dialOnly,
              );
              if (picked == null) return;
              await cubit.setMinuteOfDay(
                slot,
                picked.hour * 60 + picked.minute,
              );
            },
          ),
        ],
      ),
    );
  }
}
