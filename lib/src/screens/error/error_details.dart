import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

import 'error_screen.dart';

class ErrorDetails extends StatelessWidget {
  static const _translationKeys = {
    ErrorType.general: 'error.types.general',
    ErrorType.expired: 'error.types.expired',
    ErrorType.pairingRejected: 'error.types.pairing_rejected',
  };

  final ErrorType type;
  final String? details;
  final bool reportable;

  const ErrorDetails({required this.type, this.details, required this.reportable});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.warning_amber_rounded, color: IrmaTheme.of(context).error, size: 100),
        Padding(
            padding: EdgeInsets.all(IrmaTheme.of(context).mediumSpacing),
            child: Column(children: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    FlutterI18n.translate(context, _translationKeys[type]!),
                    style: IrmaTheme.of(context).textTheme.headline1,
                    textAlign: TextAlign.center,
                  )),
              if (reportable) ...[
                TranslatedText(
                  'error.report',
                  style: IrmaTheme.of(context).textTheme.bodyText2,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: IrmaTheme.of(context).defaultSpacing),
              ],
              if (details != null)
                Text.rich(
                  TextSpan(
                    text: FlutterI18n.translate(context, 'error.button_show_error'),
                    style: IrmaTheme.of(context).textTheme.bodyText2?.copyWith(
                          decoration: TextDecoration.underline,
                          color: IrmaTheme.of(context).linkColor,
                        ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return IrmaDialog(
                              title: FlutterI18n.translate(context, 'error.details_title'),
                              content: details ?? '',
                              child: IrmaButton(
                                size: IrmaButtonSize.small,
                                onPressed: () => Navigator.of(context).pop(),
                                label: 'error.button_ok',
                              ),
                            );
                          },
                        );
                      },
                  ),
                  textAlign: TextAlign.center,
                ),
            ])),
      ],
    ));
  }
}
