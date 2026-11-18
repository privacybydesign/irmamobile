import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/session.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/haptics.dart";
import "../../util/i18n.dart";
import "../../util/test_detection.dart";
import "../../widgets/glass/glass_sheet.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/icon_square.dart";
import "util/camera_access.dart";
import "widgets/qr_scanner.dart";

/// The QR scanner, in a sheet (on a tablet too): the sheet's bar, the
/// camera with the scan window, and under it (beside it, sideways) a panel
/// with what the scanner says and the torch.
///
/// The sheet opens before the camera is allowed: the first time the system
/// asks over it, and when access was refused the sheet says so, with a way
/// to Settings (it looks again when the app comes back).
///
/// The default behavior on scan is to dismiss the sheet and queue the
/// scanned pointer on the repo — `PendingPointerListener` (mounted on
/// `/home`) picks it up and starts the session. The same flow covers
/// both the locked case (queued pointer waits behind the lock
/// overlay's PIN) and the unlocked case (fires immediately).
///
/// With [onScanned] (the lock screen's scanner sheet) the scan goes there
/// instead, and the sheet stays.
class ScannerScreen extends ConsumerStatefulWidget {
  final void Function(Pointer pointer)? onScanned;

  const ScannerScreen({super.key, this.onScanned});

  @override
  ConsumerState<ScannerScreen> createState() => ScannerScreenState();
}

class ScannerScreenState extends ConsumerState<ScannerScreen> {
  void onQrScanned(Pointer scanned) {
    // QR was scanned using the in-app scanner, so the session
    // continues on a second device — overrule the pointer.
    final pointer = switch (scanned) {
      SessionPointer() => scanned.copyWith(continueOnSecondDevice: true),
      EmailCodePointer() => scanned,
    };

    Haptics.scanned();

    if (widget.onScanned case final onScanned?) {
      onScanned(pointer);
      return;
    }

    final pointers = ref.read(pendingPointerQueueProvider);
    Navigator.of(context).pop();
    pointers.put(pointer);
  }

  @override
  Widget build(BuildContext context) {
    // The sheet's own bar on top; the camera between it and the panel.
    return GlassSheetPage.fill(
      title: SheetTitle(context.tr("qr_scanner.title")),
      child: LayoutBuilder(
        // Sideways: wider than high (a phone held sideways).
        builder: (context, constraints) =>
            _body(constraints.maxWidth > constraints.maxHeight),
      ),
    );
  }

  Widget _body(bool side) {
    // During integration tests we can't really scan QR codes,
    // so we'll just not render the whole scanner.
    if (TestContext.isRunningIntegrationTest(context)) {
      return Container();
    }
    return CameraAccessBuilder(
      inTests: CameraAccess.granted,
      builder: (context, access) => switch (access) {
        null => const SizedBox.shrink(),
        CameraAccess.granted => QRScanner(side: side, onFound: onQrScanned),
        _ => _NoCamera(
          side: side,
          onOpenSettings: () =>
              ref.read(cameraPermissionProvider).openSettings(),
        ),
      },
    );
  }
}

/// The sheet without camera access: what is missing, and the way to
/// Settings.
class _NoCamera extends StatelessWidget {
  final bool side;
  final VoidCallback onOpenSettings;

  const _NoCamera({required this.side, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final tile = IconSquare(
      icon: Icons.no_photography_outlined,
      fill: palette.text.withValues(alpha: palette.isDark ? 0.1 : 0.06),
      ink: palette.heading,
      size: 88,
      iconSize: 40,
      radius: YiviCorners.iconTile,
    );
    final align = side ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = side ? TextAlign.start : TextAlign.center;
    final text = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Column(
        key: const Key("qr_scanner_no_camera"),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: align,
        children: [
          Semantics(
            header: true,
            child: Text(
              context.tr("qr_scanner.no_camera.title"),
              textAlign: textAlign,
              style: palette.titleSmall.copyWith(color: palette.text),
            ),
          ),
          const SizedBox(height: YiviSpace.x12),
          Text(
            context.tr("qr_scanner.no_camera.message"),
            textAlign: textAlign,
            style: palette.paragraph.copyWith(
              color: palette.secondaryText,
              height: 22 / 15,
            ),
          ),
          const SizedBox(height: YiviSpace.x16),
          SizedBox(
            width: 240,
            child: FancyPillButton(
              key: const Key("qr_scanner_open_settings"),
              label: context.tr("qr_scanner.no_camera.open_settings"),
              size: PillSize.regular,
              onPressed: onOpenSettings,
            ),
          ),
        ],
      ),
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x32),
        child: side
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(child: tile),
                  const SizedBox(width: YiviSpace.x32),
                  Flexible(child: text),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(child: tile),
                  const SizedBox(height: YiviSpace.x16),
                  text,
                ],
              ),
      ),
    );
  }
}
