import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/screens/error/error_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class ErrorDetails extends StatelessWidget {
  static const _translationKeys = {
    ErrorType.general: 'error.types.general',
    ErrorType.expired: 'error.types.expired',
    ErrorType.pairingRejected: 'error.types.pairing_rejected',
  };

  final ErrorType type;
  final String details;
  final bool reportable;

  const ErrorDetails({@required this.type, this.details, this.reportable});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: IrmaTheme.of(context).defaultSpacing,
        ),
        Center(
          child: SvgPicture.asset(
            'assets/error/general.svg',
            fit: BoxFit.scaleDown,
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(IrmaTheme.of(context).mediumSpacing),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TranslatedText(_translationKeys[type], style: IrmaTheme.of(context).textTheme.bodyText2),
                  SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                  if (reportable)
                    Column(
                      children: [
                        TranslatedText('error.report', style: IrmaTheme.of(context).textTheme.bodyText2),
                        SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                      ],
                    ),
                  if (details != null)
                    Text.rich(
                      TextSpan(
                        text: FlutterI18n.translate(context, 'error.button_show_error'),
                        style: IrmaTheme.of(context).textTheme.bodyText2.copyWith(
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
                                  content: details,
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
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
