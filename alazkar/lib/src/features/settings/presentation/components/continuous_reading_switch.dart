import 'package:alazkar/src/features/settings/presentation/controller/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContinuousReadingSwitch extends StatelessWidget {
  const ContinuousReadingSwitch({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SwitchListTile(
          secondary: const Icon(Icons.auto_stories_outlined),
          value: state.continuousReading,
          title: const Text("القراءة المتصلة"),
          subtitle: const Text(
            "السحب بعد آخر ذكر في الباب ينقلك إلى الباب التالي حتى آخر الكتاب",
          ),
          onChanged: (value) {
            context.read<SettingsCubit>().toggleContinuousReading(
                  use: !state.continuousReading,
                );
          },
        );
      },
    );
  }
}
