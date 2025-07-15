import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

import '../widgets/camera_permission_dialog.dart';

Future<void> _showCameraPermissionDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (context) => CameraPermissionDialog(),
    );

Future<bool> handleCameraPermission(BuildContext context) async {
  final cameraPermissionStatus = await Permission.camera.request();

  if (cameraPermissionStatus.isGranted) {
    return true;
  } else if (cameraPermissionStatus.isPermanentlyDenied) {
    if (context.mounted) await _showCameraPermissionDialog(context);
  }

  return false;
}
