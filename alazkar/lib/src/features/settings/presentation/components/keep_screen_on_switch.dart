import 'package:alazkar/src/features/settings/presentation/controller/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class KeepScreenOnSwitch extends StatelessWidget {
  const KeepScreenOnSwitch({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SwitchListTile(
          secondary: const Icon(Icons.light_mode),
          value: state.keepScreenOn,
          title: const Text("إبقاء الشاشة مضاءة أثناء القراءة"),
          onChanged: (value) {
            context.read<SettingsCubit>().toggleKeepScreenOn(use: value);
          },
        );
      },
    );
  }
}
