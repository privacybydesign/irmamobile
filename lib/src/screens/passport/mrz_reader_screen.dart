import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mrz_parser/mrz_parser.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import 'widgets/mzr_scanner.dart';

typedef MRZController = GlobalKey<MRZScannerState>;

/// Mzr reading is the process of obtaining mrz data via the camera
class MzrReaderScreen extends StatefulWidget {
  final Function(MRZResult mrzResult) onSuccess;
  final VoidCallback onManualAdd;
  final VoidCallback onCancel;

  const MzrReaderScreen({
    required this.onSuccess,
    required this.onManualAdd,
    required this.onCancel,
  });

  @override
  State<MzrReaderScreen> createState() => _MzrReaderScreenState();
}

class _MzrReaderScreenState extends State<MzrReaderScreen> {
  final MRZController controller = MRZController();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.portrait) {
        return Scaffold(
          backgroundColor: theme.backgroundTertiary,
          appBar: IrmaAppBar(
            titleTranslationKey: 'passport.scan.title',
          ),
          body: MRZScanner(
            controller: controller,
            showOverlay: true,
            onSuccess: (mrzResult, lines) async {
              widget.onSuccess(mrzResult);
            },
          ),
          bottomNavigationBar: IrmaBottomBar(
            primaryButtonLabel: 'passport.scan.manual',
            onPrimaryPressed: widget.onManualAdd,
            secondaryButtonLabel: 'ui.cancel',
            onSecondaryPressed: widget.onCancel,
            alignment: IrmaBottomBarAlignment.vertical,
          ),
        );
      }

      return Scaffold(
        backgroundColor: theme.backgroundTertiary,
        appBar: IrmaAppBar(
          titleTranslationKey: 'passport.scan.title',
          leading: YiviBackButton(
            key: const Key('bottom_bar_secondary'),
            onTap: widget.onCancel,
          ),
        ),
        body: MRZScanner(
          controller: controller,
          showOverlay: true,
          onSuccess: (mrzResult, lines) async {
            widget.onSuccess(mrzResult);
          },
        ),
        floatingActionButton: _ManualEntryButton(
          key: const Key('bottom_bar_primary'),
          onTap: widget.onManualAdd,
        ),
      );
    });
  }
}

class _ManualEntryButton extends StatelessWidget {
  const _ManualEntryButton({super.key, required this.onTap});

  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SizedBox(
      height: 72,
      width: 72,
      child: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/ui/round-btn-bg.svg',
            ),
          ),
          Positioned.fill(
            child: ClipOval(
              child: Material(
                type: MaterialType.transparency,
                child: Semantics(
                  button: true,
                  label: FlutterI18n.translate(context, 'passport.scan.manual'),
                  child: InkWell(
                    onTap: onTap,
                    child: Icon(
                      Icons.edit,
                      color: theme.light,
                      size: 42,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
