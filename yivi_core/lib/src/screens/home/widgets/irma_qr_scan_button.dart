import "package:material_ui/material_ui.dart";

import "../../../widgets/glass/glass_sheet.dart";
import "../../scanner/lock_scanner_sheet.dart";
import "../../scanner/scanner_screen.dart";

/// Opens the QR scanner as a sheet on whichever Navigator owns [context]
/// (on a tablet the app's sheet is a dialog in the middle). The scanner
/// dismisses itself on scan and queues the pointer via the repo, so the
/// same call site works whether the app is locked (overlay's local
/// Navigator owns the sheet) or unlocked (GoRouter's main Navigator owns
/// it). The sheet asks for the camera itself.
///
/// From the lock screen ([lockScreen]) the scanner is the first page of a
/// sheet that goes on after the scan: the PIN, then an issuance in the same
/// sheet ([LockScannerSheet]).
Future<void> openQrCodeScanner(
  BuildContext context, {
  bool lockScreen = false,
}) => showGlassSheet<void>(
  context: context,
  builder: (_) => lockScreen ? const LockScannerSheet() : const ScannerScreen(),
);
