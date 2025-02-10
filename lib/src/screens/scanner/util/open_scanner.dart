import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/irma_repository.dart';
import '../scanner_screen.dart';

Future<void> maybeOpenQrScanner(
  IrmaRepository repo,
  BuildContext context,
) async {
  // Another screen is already present top of the HomeScreen, so don't open the scanner
  if (context.canPop()) return;

  // Check if the setting is enabled to open the QR scanner on start up
  final startQrScannerOnStartUp = await repo.preferences.getStartQRScan().first;

  if (startQrScannerOnStartUp) {
    // Check if we actually have permission to use the camera
    final hasCameraPermission = await Permission.camera.isGranted;

    if (hasCameraPermission) {
      // Check if the app was started with a HandleURLEvent or resumed when returning from in-app browser.
      // If so, do not open the QR scanner.
      final appResumedAutomatically = await repo.appResumedAutomatically();
      if (!appResumedAutomatically) {
        if (!context.mounted) {
          return;
        }
        context.go('/scanner');
      }
    } else {
      // If the user has revoked the camera permission, just turn off the setting
      await repo.preferences.setStartQRScan(false);
    }
  }
}
