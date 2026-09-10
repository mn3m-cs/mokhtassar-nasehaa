import 'package:alazkar/src/features/zikr_source_filter/presentation/controller/cubit/zikr_source_filter_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShowOnlyWithFadlSwitch extends StatelessWidget {
  const ShowOnlyWithFadlSwitch({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ZikrSourceFilterCubit, ZikrSourceFilterState>(
      builder: (context, state) {
        return SwitchListTile(
          secondary: const Icon(
            Icons.emoji_events_rounded,
          ),
          title: const Text("عرض الأذكار ذات الفضل فقط"),
          value: state.showOnlyWithFadl,
          onChanged: (value) {
            context.read<ZikrSourceFilterCubit>().toggleShowOnlyWithFadl(value);
          },
        );
      },
    );
  }
}
