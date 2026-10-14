import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:permission_handler/permission_handler.dart";

import "../../../../package_name.dart";
import "../../../data/feature_flags.dart";
import "../../../providers/feature_flag_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/missing_data_flow.dart";
import "../../../util/test_detection.dart";
import "../../../widgets/document_flow_footer.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/translated_text.dart";
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
  final CameraOverlayBuilder overlayBuilder;

  const MrzReaderScreen({
    required this.overlayBuilder,
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
    final documentFlowV2 =
        ref.watch(featureFlagProvider(FeatureFlag.documentFlowV2)).value ??
        false;

    final body = switch (_cameraPermissionStatus) {
      .granted => MrzScanner(
        controller: controller,
        overlayBuilder: widget.overlayBuilder,
        onSuccess: widget.onSuccess,
        mrzParser: widget.mrzParser,
      ),
      _ => SingleChildScrollView(
        child: Padding(
          padding: .all(theme.defaultSpacing),
          child: Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .center,
            children: [
              TranslatedText(
                "mrz_camera_permissions.title",
                style: theme.textTheme.displaySmall,
                textAlign: .center,
              ),
              SizedBox(height: theme.smallSpacing),
              TranslatedText(
                "mrz_camera_permissions.content",
                textAlign: .center,
              ),
              SizedBox(height: theme.largeSpacing),
              TextButton(
                child: TranslatedText(
                  "mrz_camera_permissions.open_settings",
                  style: theme.textButtonTextStyle.copyWith(
                    fontWeight: .normal,
                    color: theme.link,
                  ),
                ),
                onPressed: () async {
                  await openAppSettings();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    };

    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == .portrait) {
          return Scaffold(
            backgroundColor: theme.backgroundTertiary,
            appBar: IrmaAppBar(
              bottom: context.missingDataBand,
              titleTranslationKey: widget.translationKeys.title,
              hasBorder: !documentFlowV2,
            ),
            body: body,
            bottomNavigationBar: documentFlowV2
                ? DocumentFlowFooter(
                    buttons: [
                      DocumentFlowButton(
                        key: DocumentFlowButton.primaryKey,
                        labelKey: widget.translationKeys.manualEntryButton,
                        onPressed: widget.onManualAdd,
                      ),
                      DocumentFlowButton(
                        key: DocumentFlowButton.secondaryKey,
                        labelKey: context.missingDataBackLabel(
                          "document_flow.cancel",
                        ),
                        onPressed: widget.onCancel,
                        style: .outline,
                      ),
                    ],
                  )
                : IrmaBottomBar(
                    primaryButtonLabel:
                        widget.translationKeys.manualEntryButton,
                    onPrimaryPressed: widget.onManualAdd,
                    secondaryButtonLabel: context.missingDataBackLabel(
                      "ui.cancel",
                    ),
                    onSecondaryPressed: widget.onCancel,
                    alignment: .vertical,
                  ),
          );
        }

        return Scaffold(
          backgroundColor: theme.backgroundTertiary,
          appBar: IrmaAppBar(
            bottom: context.missingDataBand,
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
