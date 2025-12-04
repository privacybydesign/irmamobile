import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/svg.dart";
import "package:mrz_parser/mrz_parser.dart";

import "../../../package_name.dart";
import "../../theme/theme.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
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
class MrzReaderScreen<Parser extends MrzParser> extends StatefulWidget {
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
  State<MrzReaderScreen> createState() => _MrzReaderScreenState();
}

class _MrzReaderScreenState extends State<MrzReaderScreen> {
  final MrzController controller = MrzController();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == .portrait) {
          return Scaffold(
            backgroundColor: theme.backgroundTertiary,
            appBar: IrmaAppBar(
              titleTranslationKey: widget.translationKeys.title,
            ),
            body: MrzScanner(
              controller: controller,
              overlayBuilder: widget.overlayBuilder,
              onSuccess: widget.onSuccess,
              mrzParser: widget.mrzParser,
            ),
            bottomNavigationBar: IrmaBottomBar(
              primaryButtonLabel: widget.translationKeys.manualEntryButton,
              onPrimaryPressed: widget.onManualAdd,
              secondaryButtonLabel: "ui.cancel",
              onSecondaryPressed: widget.onCancel,
              alignment: .vertical,
            ),
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
          body: MrzScanner(
            controller: controller,
            overlayBuilder: widget.overlayBuilder,
            onSuccess: widget.onSuccess,
            mrzParser: widget.mrzParser,
          ),
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
                    child: Icon(Icons.edit, color: theme.light, size: 42),
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
