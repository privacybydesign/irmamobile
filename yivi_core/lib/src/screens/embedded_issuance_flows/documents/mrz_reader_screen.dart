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
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/translated_text.dart";
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

  /// The progress under the bar, when the screen is a step in a sheet.
  final PreferredSizeWidget? band;

  const MrzReaderScreen({
    required this.translationKeys,
    required this.onSuccess,
    required this.onManualAdd,
    required this.onCancel,
    required this.mrzParser,
    this.band,
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
            band: widget.band,
          );
        }

        return Scaffold(
          backgroundColor: theme.backgroundTertiary,
          appBar: IrmaAppBar(
            titleTranslationKey: widget.translationKeys.title,
            bottom: widget.band,
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
    final theme = IrmaTheme.of(context);

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
                    onTap: onTap,
                    child: Icon(Icons.edit, color: theme.onPrimary, size: 42),
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

  /// The progress on a glass strip under the title, in a sheet.
  final PreferredSizeWidget? band;

  const _CameraScaffold({
    required this.title,
    required this.body,
    required this.manualLabel,
    required this.cancelLabel,
    required this.onManual,
    required this.onCancel,
    this.band,
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
                    child: DarkGlassIconButton(
                      key: const Key("irma_app_bar_leading"),
                      icon: Icons.arrow_back_rounded,
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
            if (band case final band?)
              Positioned(
                left: 16 + padding.left,
                right: 16 + padding.right,
                top: padding.top + 68,
                // A light strip, readable over the camera picture.
                child: DecoratedBox(
                  decoration: const ShapeDecoration(
                    color: Color(0xE6FFFFFF),
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.all(Radius.circular(22)),
                    ),
                  ),
                  // The band pads its sides and bottom; the top matches.
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: band,
                  ),
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
                    _CameraPill(
                      key: const Key("bottom_bar_primary"),
                      label: FlutterI18n.translate(context, manualLabel),
                      outlined: true,
                      onTap: onManual,
                    ),
                    _CameraPill(
                      key: const Key("bottom_bar_secondary"),
                      label: FlutterI18n.translate(context, cancelLabel),
                      onTap: onCancel,
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

/// A white pill on the dark panel: outlined and 52 high for the main
/// action, plain text and 48 high otherwise. Grows with large text.
class _CameraPill extends StatelessWidget {
  final String label;
  final bool outlined;
  final VoidCallback onTap;

  const _CameraPill({
    super.key,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Material(
          color: outlined ? const Color(0x14FFFFFF) : Colors.transparent,
          shape: StadiumBorder(
            side: outlined
                ? const BorderSide(color: Color(0xB3FFFFFF))
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: outlined ? 52 : 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: palette
                        .display(16, weight: FontWeight.w700)
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
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
            TextButton(
              onPressed: () async {
                await openAppSettings();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: TranslatedText(
                "mrz_camera_permissions.open_settings",
                style: palette
                    .body(16, weight: FontWeight.w700)
                    .copyWith(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
