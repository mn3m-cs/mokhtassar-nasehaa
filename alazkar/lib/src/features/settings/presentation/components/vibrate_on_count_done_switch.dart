import 'package:alazkar/src/features/settings/presentation/controller/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VibrateOnCountDoneSwitch extends StatelessWidget {
  const VibrateOnCountDoneSwitch({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SwitchListTile(
          secondary: const Icon(Icons.vibration),
          value: state.vibrateOnCountDone,
          title: const Text("الاهتزاز عند تمام العدد"),
          subtitle: const Text("في الأذكار التي تتكرر أكثر من مرة"),
          onChanged: (value) {
            context.read<SettingsCubit>().toggleVibrateOnCountDone(use: value);
          },
        );
      },
    );
  }
}
