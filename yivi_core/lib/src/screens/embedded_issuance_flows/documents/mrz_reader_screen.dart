import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:permission_handler/permission_handler.dart";

import "../../../../package_name.dart";
import "../../../theme/theme.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/test_detection.dart";
import "../../../widgets/glass/floating_bar_placement.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/translated_text.dart";
import "document_step_in_sheet.dart";
import "widgets/dark_glass.dart";
import "widgets/mrz_scanner.dart";

typedef MrzController = GlobalKey<MrzScannerState>;

class MrzReaderTranslationKeys {
  final String title;
  final String manualEntryButton;
  final String error;
  final String success;
  final String successExplanation;

  MrzReaderTranslationKeys({
    required this.title,
    required this.manualEntryButton,
    required this.error,
    required this.success,
    required this.successExplanation,
  });
}

/// Mzr reading is the process of obtaining mrz data via the camera
class MrzReaderScreen<Parser extends MrzParser> extends ConsumerStatefulWidget {
  final void Function(MrzResult mrzResult) onSuccess;
  final VoidCallback onManualAdd;
  final VoidCallback onCancel;
  final Parser mrzParser;
  final MrzReaderTranslationKeys translationKeys;

  const MrzReaderScreen({
    required this.translationKeys,
    required this.onSuccess,
    required this.onManualAdd,
    required this.onCancel,
    required this.mrzParser,
  });

  @override
  ConsumerState<MrzReaderScreen> createState() => MrzReaderScreenState();
}

class MrzReaderScreenState extends ConsumerState<MrzReaderScreen> {
  final MrzController controller = MrzController();
  late PermissionStatus _cameraPermissionStatus = .denied;

  @override
  void initState() {
    super.initState();
    initCameraPermission();
  }

  void initCameraPermission() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (TestContext.isRunningIntegrationTest(context)) {
        return;
      }
      final status = await Permission.camera.request();
      setState(() {
        _cameraPermissionStatus = status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final body = _cameraPermissionStatus == .granted
        ? MrzScanner(
            controller: controller,
            onSuccess: widget.onSuccess,
            mrzParser: widget.mrzParser,
          )
        : const _DarkPermissionFallback();

    // In a sheet, as on the canvas: the picture in a rounded card under the
    // sheet's bar, "Enter manually" under it, no Cancel.
    if (DocumentStepInSheet.of(context)) {
      return _SheetCamera(
        body: body,
        manualLabel: widget.translationKeys.manualEntryButton,
        onManual: widget.onManualAdd,
      );
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        // The redesign's camera: the picture fills the screen under a
        // floating title and a dark glass panel with the buttons.
        if (orientation == .portrait) {
          return _CameraScaffold(
            title: widget.translationKeys.title,
            body: body,
            manualLabel: widget.translationKeys.manualEntryButton,
            cancelLabel: "document_flow.cancel",
            onManual: widget.onManualAdd,
            onCancel: widget.onCancel,
          );
        }

        return Scaffold(
          backgroundColor: theme.backgroundTertiary,
          appBar: IrmaAppBar(
            titleTranslationKey: widget.translationKeys.title,
            leading: YiviBackButton(
              key: const Key("bottom_bar_secondary"),
              onTap: widget.onCancel,
            ),
          ),
          body: body,
          floatingActionButton: _ManualEntryButton(
            label: FlutterI18n.translate(
              context,
              widget.translationKeys.manualEntryButton,
            ),
            key: const Key("bottom_bar_primary"),
            onTap: widget.onManualAdd,
          ),
        );
      },
    );
  }
}

class _ManualEntryButton extends StatelessWidget {
  const _ManualEntryButton({
    super.key,
    required this.onTap,
    required this.label,
  });

  final Function() onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      width: 72,
      child: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(yiviAsset("ui/round-btn-bg.svg")),
          ),
          Positioned.fill(
            child: ClipOval(
              child: Material(
                type: .transparency,
                child: Semantics(
                  button: true,
                  label: label,
                  child: InkWell(
                    highlightColor: Colors.transparent,
                    onTap: onTap,
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The camera screen of the redesign: the camera behind everything, the
/// title and a dark glass back button floating over it at the top, and the
/// buttons on a dark glass panel at the bottom.
class _CameraScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String manualLabel;
  final String cancelLabel;
  final VoidCallback onManual;
  final VoidCallback onCancel;

  const _CameraScaffold({
    required this.title,
    required this.body,
    required this.manualLabel,
    required this.cancelLabel,
    required this.onManual,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status bar icons over the dark camera.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF121417),
        body: Stack(
          fit: StackFit.expand,
          children: [
            body,
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
                    child: GlassIconButton(
                      key: const Key("irma_app_bar_leading"),
                      dark: true,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                      semanticsLabel: FlutterI18n.translate(
                        context,
                        "ui.go_back",
                      ),
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16 + padding.left,
              right: 16 + padding.right,
              bottom: 24 + padding.bottom,
              child: DarkGlass(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                ),
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
                      label: FlutterI18n.translate(context, cancelLabel),
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
  final Widget body;
  final String manualLabel;
  final VoidCallback onManual;

  const _SheetCamera({
    required this.body,
    required this.manualLabel,
    required this.onManual,
  });

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: ClipRSuperellipse(
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              child: ColoredBox(color: const Color(0xFF121417), child: body),
            ),
          ),
          PillButton(
            key: const Key("bottom_bar_primary"),
            label: FlutterI18n.translate(context, manualLabel),
            onPressed: onManual,
          ),
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
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          32,
          padding.top + 84,
          32,
          padding.bottom + 180,
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
