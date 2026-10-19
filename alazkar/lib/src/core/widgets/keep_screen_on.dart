import 'package:alazkar/src/core/manager/screen_awake_manager.dart';
import 'package:flutter/widgets.dart';

/// Keeps the screen on while it is in the tree, the app is in front and
/// [enabled] is true; releases it on leaving, in the background, or when
/// [enabled] turns false.
class KeepScreenOn extends StatefulWidget {
  final bool enabled;
  final Widget child;
  const KeepScreenOn({super.key, required this.enabled, required this.child});

  @override
  State<KeepScreenOn> createState() => _KeepScreenOnState();
}

class _KeepScreenOnState extends State<KeepScreenOn>
    with WidgetsBindingObserver {
  bool _inFront = true;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inFront = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _apply();
  }

  @override
  void didUpdateWidget(KeepScreenOn oldWidget) {
    super.didUpdateWidget(oldWidget);
    _apply();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inFront = state == AppLifecycleState.resumed;
    _apply();
  }

  void _apply() {
    final want = widget.enabled && _inFront;
    if (want == _requested) return;
    _requested = want;
    ScreenAwakeManager.keepOn(want);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_requested) ScreenAwakeManager.keepOn(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
