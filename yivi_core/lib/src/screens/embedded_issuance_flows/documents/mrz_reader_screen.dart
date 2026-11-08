import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:permission_handler/permission_handler.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/test_detection.dart";
import "../../../widgets/floating_bar_placement.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/glass/round_icon_button.dart";
import "../../../widgets/glass/sheet_actions.dart";
import "../../../widgets/glass/sheet_layout.dart";
import "../../../widgets/translated_text.dart";
import "document_instruction_screen.dart" show DocumentTipBox;
import "document_step_in_sheet.dart";
import "widgets/dark_glass.dart";
import "widgets/document_camera_frame.dart";
import "widgets/mrz_scanner.dart";

class MrzReaderTranslationKeys {
  final String title;
  final String manualEntryButton;

  MrzReaderTranslationKeys({
    required this.title,
    required this.manualEntryButton,
  });
}

/// Reads the MRZ of a document with the camera.
class MrzReaderScreen<Parser extends MrzParser> extends ConsumerStatefulWidget {
  final void Function(MrzResult mrzResult) onSuccess;
  final VoidCallback onManualAdd;
  final VoidCallback onCancel;
  final Parser mrzParser;
  final MrzReaderTranslationKeys translationKeys;

  /// The document's instruction ("Open your passport on …", its tip): what
  /// the camera step says beside the camera in a sheet held sideways.
  final String? instructionKey;

  const MrzReaderScreen({
    required this.translationKeys,
    this.instructionKey,
    required this.onSuccess,
    required this.onManualAdd,
    required this.onCancel,
    required this.mrzParser,
  });

  @override
  ConsumerState<MrzReaderScreen> createState() => MrzReaderScreenState();
}

class MrzReaderScreenState extends ConsumerState<MrzReaderScreen> {
  // One scanner across the portrait and landscape layouts: the key keeps its
  // state (and the camera) when the device turns.
  final _scannerKey = GlobalKey<MrzScannerState>();
  late PermissionStatus _cameraPermissionStatus = .denied;

  @override
  void initState() {
    super.initState();
    _initCameraPermission();
  }

  void _initCameraPermission() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (TestContext.isRunningIntegrationTest(context)) {
        return;
      }
      final status = await Permission.camera.request();
      if (!mounted) return;
      setState(() {
        _cameraPermissionStatus = status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = _cameraPermissionStatus == .granted
        ? MrzScanner(
            key: _scannerKey,
            onSuccess: widget.onSuccess,
            mrzParser: widget.mrzParser,
          )
        : const _DarkPermissionFallback();

    // In a sheet, as on the canvas: the picture in a rounded card under the
    // sheet's bar, "Enter manually" under it, no Cancel.
    if (DocumentStepInSheet.of(context)) {
      return _SheetCamera(
        titleKey: widget.translationKeys.title,
        body: body,
        manualLabel: widget.translationKeys.manualEntryButton,
        onManual: widget.onManualAdd,
        instructionKey: widget.instructionKey,
      );
    }

    // The picture fills the screen under a floating title and a dark glass
    // panel with the buttons: at the bottom, or at the right held sideways.
    return _CameraScaffold(
      title: widget.translationKeys.title,
      body: body,
      manualLabel: widget.translationKeys.manualEntryButton,
      onManual: widget.onManualAdd,
      onCancel: widget.onCancel,
    );
  }
}

/// The camera screen: the camera behind everything, the title and a dark
/// glass back button floating over it at the top, and the buttons on a dark
/// glass panel at the bottom; held sideways, [_sideWidth] wide at the bottom
/// right, with the window beside it ([CameraSidePanel]).
class _CameraScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String manualLabel;
  final VoidCallback onManual;
  final VoidCallback onCancel;

  const _CameraScaffold({
    required this.title,
    required this.body,
    required this.manualLabel,
    required this.onManual,
    required this.onCancel,
  });

  static const _sideWidth = 220.0;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final sideways = size.width > size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status bar icons over the dark camera.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: cameraDark,
        body: Stack(
          fit: StackFit.expand,
          children: [
            CameraSidePanel(
              width: sideways ? 16 + padding.right + _sideWidth + 16 : 0,
              child: body,
            ),
            Positioned(
              left: 16 + padding.left,
              right: 16 + padding.right,
              top: padding.top + 16,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 52),
                    child: Semantics(
                      header: true,
                      child: Text(
                        FlutterI18n.translate(context, title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: palette
                            .display(18)
                            .copyWith(
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Color(0x73000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RoundIconButton(
                      key: const Key("irma_app_bar_leading"),
                      dark: true,
                      icon: CupertinoIcons.arrow_left,
                      label: FlutterI18n.translate(context, "ui.go_back"),
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: sideways ? null : 16 + padding.left,
              right: 16 + padding.right,
              bottom: (sideways ? 16 : 24) + padding.bottom,
              width: sideways ? _sideWidth : null,
              child: DarkGlass(
                borderRadius: YiviCorners.cardRadius,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 4,
                  children: [
                    PillButton(
                      key: const Key("bottom_bar_primary"),
                      label: FlutterI18n.translate(context, manualLabel),
                      onDark: true,
                      onPressed: onManual,
                    ),
                    PillButton(
                      key: const Key("bottom_bar_secondary"),
                      label: FlutterI18n.translate(
                        context,
                        "document_flow.cancel",
                      ),
                      style: PillStyle.text,
                      onDark: true,
                      onPressed: onCancel,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The camera as a step in a sheet: the picture in a rounded card filling
/// the page under the sheet's bar, and "Enter manually" under it.
class _SheetCamera extends StatelessWidget {
  /// The page's heading upright ("Scan passport"), above the camera.
  final String titleKey;
  final Widget body;
  final String manualLabel;
  final VoidCallback onManual;
  final String? instructionKey;

  const _SheetCamera({
    required this.titleKey,
    required this.body,
    required this.manualLabel,
    required this.onManual,
    this.instructionKey,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: YiviCorners.cardRadius,
      child: ColoredBox(color: cameraDark, child: body),
    );
    // The camera moves on by itself: no way on, only "Enter manually", the
    // other choice. Upright in a sheet it is in the page's bottom bar, which
    // stays put; with the way on in the sheet's bar, a link.
    if (SheetSlotAction.atBottom(context)) {
      return SheetSlotAction(
        action: null,
        secondary: SheetAction(
          key: const Key("bottom_bar_primary"),
          label: FlutterI18n.translate(context, manualLabel),
          onTap: onManual,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The page's heading, as on every step of adding a card.
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                child: TranslatedText(
                  titleKey,
                  key: const Key("sheet_camera_heading"),
                  isHeader: true,
                  textAlign: TextAlign.center,
                  style: YiviPalette.of(context)
                      .display(22, weight: FontWeight.w700)
                      .copyWith(
                        height: 30 / 22,
                        color: YiviPalette.of(context).heading,
                      ),
                ),
              ),
              Expanded(child: card),
            ],
          ),
        ),
      );
    }
    final inBar = sheetActionInBar(context);
    final Widget manual = inBar
        ? SheetSlotAction(
            action: null,
            child: Center(
              child: TextLink(
                key: const Key("bottom_bar_primary"),
                label: FlutterI18n.translate(context, manualLabel),
                onPressed: onManual,
              ),
            ),
          )
        : PillButton(
            key: const Key("bottom_bar_primary"),
            label: FlutterI18n.translate(context, manualLabel),
            onPressed: onManual,
          );
    // Held sideways: what to do and "Enter manually" at the left, the
    // camera at the right.
    final instruction = instructionKey;
    if (useSheetColumns(context)) {
      final palette = YiviPalette.of(context);
      return SheetSplit(
        endFills: true,
        start: [
          if (instruction != null) ...[
            TranslatedText(
              "$instruction.title",
              isHeader: true,
              style: palette
                  .display(20, weight: FontWeight.w700)
                  .copyWith(height: 28 / 20, color: palette.heading),
            ),
            DocumentTipBox(textKey: "$instruction.tip"),
          ],
        ],
        end: card,
        actions: manual,
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        FloatingBarPlacement.buttonBottom(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Expanded(child: card),
          manual,
        ],
      ),
    );
  }
}

/// Without camera permission, on the dark camera screen: what to do, in
/// white, between the title and the buttons.
class _DarkPermissionFallback extends StatelessWidget {
  const _DarkPermissionFallback();

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    // Clear of the buttons: under it, or beside it held sideways.
    final beside = CameraSidePanel.widthOf(context);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          32,
          padding.top + 84,
          beside > 0 ? beside : 32,
          padding.bottom + (beside > 0 ? 16 : 180),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            TranslatedText(
              "mrz_camera_permissions.title",
              isHeader: true,
              textAlign: TextAlign.center,
              style: palette
                  .display(22, weight: FontWeight.w700)
                  .copyWith(height: 30 / 22, color: Colors.white),
            ),
            TranslatedText(
              "mrz_camera_permissions.content",
              textAlign: TextAlign.center,
              style: palette
                  .body(16)
                  .copyWith(height: 24 / 16, color: const Color(0xD9FFFFFF)),
            ),
            TextLink(
              label: FlutterI18n.translate(
                context,
                "mrz_camera_permissions.open_settings",
              ),
              color: Colors.white,
              onPressed: () async {
                await openAppSettings();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
