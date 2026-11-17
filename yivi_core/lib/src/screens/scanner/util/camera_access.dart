import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:permission_handler/permission_handler.dart";

import "../../../util/after_frame.dart";
import "../../../util/test_detection.dart";

/// Whether the scanner may use the camera.
enum CameraAccess {
  granted,

  /// Not asked yet (or, on Android, refused once): the system can ask.
  askable,

  /// Refused for good or restricted: only Settings can change it.
  denied,
}

/// Asks the system for the camera; a provider, so tests can stand in.
abstract class CameraPermission {
  Future<CameraAccess> status();

  /// Shows the system's question, where it still can.
  Future<CameraAccess> request();

  /// Opens the app's page in the system settings.
  Future<void> openSettings();
}

final cameraPermissionProvider = Provider<CameraPermission>(
  (_) => const _SystemCameraPermission(),
);

class _SystemCameraPermission implements CameraPermission {
  const _SystemCameraPermission();

  static CameraAccess _access(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return CameraAccess.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CameraAccess.denied;
    }
    return CameraAccess.askable;
  }

  @override
  Future<CameraAccess> status() async =>
      _access(await Permission.camera.status);

  @override
  Future<CameraAccess> request() async =>
      _access(await Permission.camera.request());

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }
}

/// Looks up the camera permission, asks once where it may, and looks again
/// when the app comes back (from Settings). Once asked, anything but yes is
/// [CameraAccess.denied]: only Settings can change it. In integration tests
/// it answers [inTests] without asking, as there is no camera to ask for.
class CameraAccessBuilder extends ConsumerStatefulWidget {
  /// Builds with the access, null while it is being looked up.
  final Widget Function(BuildContext context, CameraAccess? access) builder;

  /// The answer during integration tests.
  final CameraAccess inTests;

  const CameraAccessBuilder({
    super.key,
    required this.builder,
    required this.inTests,
  });

  @override
  ConsumerState<CameraAccessBuilder> createState() =>
      _CameraAccessBuilderState();
}

class _CameraAccessBuilderState extends ConsumerState<CameraAccessBuilder>
    with WidgetsBindingObserver {
  CameraAccess? _access;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    afterFrame(() => _check(ask: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from Settings (or the system's question): look again.
    if (state == AppLifecycleState.resumed &&
        _access != null &&
        _access != CameraAccess.granted) {
      _check();
    }
  }

  Future<void> _check({bool ask = false}) async {
    if (!mounted) return;
    if (TestContext.isRunningIntegrationTest(context)) {
      setState(() => _access = widget.inTests);
      return;
    }
    final permission = ref.read(cameraPermissionProvider);
    var access = await permission.status();
    if (access == CameraAccess.askable && ask) {
      access = await permission.request();
    }
    if (!mounted) return;
    setState(
      () => _access = access == CameraAccess.granted
          ? CameraAccess.granted
          : CameraAccess.denied,
    );
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _access);
}
