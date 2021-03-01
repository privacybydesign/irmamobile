import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

class GeneralError extends StatelessWidget {
  final String errorText;

  const GeneralError({@required this.errorText});

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
                children: <Widget>[
                  Text.rich(
                    TextSpan(
                      text: FlutterI18n.translate(context, "error.types.general"),
                      style: IrmaTheme.of(context).textTheme.bodyText2,
                      children: <TextSpan>[
                        TextSpan(
                          text: "\n\n ${FlutterI18n.translate(context, 'error.button_show_error')}",
                          style: IrmaTheme.of(context).textTheme.bodyText2.copyWith(
                                decoration: TextDecoration.underline,
                                color: IrmaTheme.of(context).linkColor,
                              ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(
                                      "Foutmelding",
                                      style: IrmaTheme.of(context).textTheme.headline3,
                                    ),
                                    content: Container(
                                      width: MediaQuery.of(context).size.width,
                                      child: Text(
                                        errorText,
                                        style: IrmaTheme.of(context).textTheme.bodyText2,
                                      ),
                                    ),
                                    actions: <Widget>[
                                      IrmaButton(
                                        label: FlutterI18n.translate(context, 'error.button_ok'),
                                        textStyle: IrmaTheme.of(context).textTheme.button,
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                        ),
                      ],
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
