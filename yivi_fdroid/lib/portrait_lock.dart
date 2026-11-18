import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

/// Holds the app in portrait while [child] is on screen, and allows every
/// orientation again once it is gone, as the app does everywhere else.
///
/// Regula's web Face SDK ends a capture as soon as its page turns to landscape
/// (`LANDSCAPE_MODE_RESTRICTED`) or rotates at all (`DEVICE_ROTATE`). It watches
/// the page's own orientation, not the motion sensor, so holding the app in
/// portrait keeps a phone tilted mid-capture from failing the face check.
class PortraitLock extends StatefulWidget {
  const PortraitLock({super.key, required this.child});

  final Widget child;

  @override
  State<PortraitLock> createState() => _PortraitLockState();
}

class _PortraitLockState extends State<PortraitLock> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
