import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:permission_handler/permission_handler.dart";

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

  static CameraAccess _access(PermissionStatus status) =>
      status.isGranted || status.isLimited
      ? CameraAccess.granted
      : status.isPermanentlyDenied || status.isRestricted
      ? CameraAccess.denied
      : CameraAccess.askable;

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
