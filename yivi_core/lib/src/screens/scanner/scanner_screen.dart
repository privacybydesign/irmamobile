import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/session.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../util/test_detection.dart";
import "../../widgets/glass/glass_surface.dart";
import "../../widgets/glass/pill_buttons.dart";
import "util/camera_access.dart";
import "widgets/qr_scanner.dart";

/// The QR scanner, in a sheet (on a tablet too): the camera to the sheet's
/// edges, the scan window, and what the scanner says.
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

class ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  final _qrKey = GlobalKey<QRScannerState>(debugLabel: "qr_scanner_key");

  /// Null while it is being looked up.
  CameraAccess? _access;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check(ask: true));
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
    // During integration tests there is no camera to ask for.
    if (TestContext.isRunningIntegrationTest(context)) {
      setState(() => _access = CameraAccess.granted);
      return;
    }
    final permission = ref.read(cameraPermissionProvider);
    var access = await permission.status();
    if (access == CameraAccess.askable && ask) {
      access = await permission.request();
    }
    if (!mounted) return;
    // Once asked, anything but yes sends the user to Settings.
    setState(
      () => _access = access == CameraAccess.granted
          ? CameraAccess.granted
          : CameraAccess.denied,
    );
  }

  void onQrScanned(Pointer pointer) {
    if (pointer is SessionPointer) {
      // QR was scanned using the in-app scanner, so the session
      // continues on a second device — overrule the pointer.
      pointer.continueOnSecondDevice = true;
    }

    HapticFeedback.vibrate();

    if (widget.onScanned case final onScanned?) {
      onScanned(pointer);
      return;
    }

    final repo = IrmaRepositoryProvider.of(context);
    Navigator.of(context).pop();
    repo.setPendingPointer(pointer);
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF15181C),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Sideways: wider than high (a phone held sideways).
          final side = constraints.maxWidth > constraints.maxHeight;
          final close = GlassIconButton(
            key: const Key("irma_app_bar_close"),
            semanticsLabel: FlutterI18n.translate(context, "ui.close"),
            dark: true,
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
            onTap: () => Navigator.of(context).pop(),
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: _body(side)),
              // Upright the title is centred at the top; sideways it is in
              // the scanner's column, and only the close button is up here.
              Positioned(
                left: 16,
                right: 16,
                top: side ? 12 : 16,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!side)
                      Semantics(
                        header: true,
                        child: Text(
                          FlutterI18n.translate(context, "qr_scanner.title"),
                          style: palette
                              .display(17)
                              .copyWith(
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x73000000),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                        ),
                      ),
                    Align(alignment: Alignment.centerRight, child: close),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _body(bool side) {
    // During integration tests we can't really scan QR codes,
    // so we'll just not render the whole scanner.
    if (TestContext.isRunningIntegrationTest(context)) {
      return Container();
    }
    return switch (_access) {
      null => const SizedBox.shrink(),
      CameraAccess.granted => QRScanner(
        key: _qrKey,
        side: side,
        onFound: onQrScanned,
      ),
      _ => _NoCamera(
        side: side,
        onOpenSettings: () => ref.read(cameraPermissionProvider).openSettings(),
      ),
    };
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
    final tile = Container(
      width: 88,
      height: 88,
      decoration: const ShapeDecoration(
        color: Color(0x14FFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YiviCorners.iconTile)),
        ),
      ),
      child: const Icon(
        Icons.no_photography_outlined,
        size: 40,
        color: Colors.white,
      ),
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
              FlutterI18n.translate(context, "qr_scanner.no_camera.title"),
              textAlign: textAlign,
              style: palette.display(20).copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            FlutterI18n.translate(context, "qr_scanner.no_camera.message"),
            textAlign: textAlign,
            style: palette
                .body(14.5)
                .copyWith(color: const Color(0xD9FFFFFF), height: 21 / 14.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 240,
            child: FancyPillButton(
              key: const Key("qr_scanner_open_settings"),
              label: FlutterI18n.translate(
                context,
                "qr_scanner.no_camera.open_settings",
              ),
              size: PillSize.regular,
              onPressed: onOpenSettings,
            ),
          ),
        ],
      ),
    );
    return ColoredBox(
      color: const Color(0xFF1C1F23),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: side
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(child: tile),
                    const SizedBox(width: 28),
                    Flexible(child: text),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(child: tile),
                    const SizedBox(height: 14),
                    text,
                  ],
                ),
        ),
      ),
    );
  }
}
