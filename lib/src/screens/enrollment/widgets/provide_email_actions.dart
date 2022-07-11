// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class ProvideEmailActions extends StatelessWidget {
  final void Function() submitEmail;
  final void Function() skipEmail;
  final void Function() enterEmail;

  const ProvideEmailActions({
    @required this.submitEmail,
    @required this.skipEmail,
    @required this.enterEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
          color: IrmaTheme.of(context).background,
          child: Row(
            children: <Widget>[
              Expanded(
                child: IrmaTextButton(
                  key: const Key('enrollment_skip_email'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => IrmaDialog(
                        title: FlutterI18n.translate(context, 'enrollment.provide_email.skip_title'),
                        content: FlutterI18n.translate(context, 'enrollment.provide_email.skip_content'),
                        child: Wrap(
                          direction: Axis.horizontal,
                          verticalDirection: VerticalDirection.up,
                          alignment: WrapAlignment.spaceEvenly,
                          children: <Widget>[
                            IrmaTextButton(
                              onPressed: () {
                                skipEmail();
                                Navigator.of(context).pop();
                              },
                              minWidth: 0.0,
                              label: 'enrollment.provide_email.skip',
                              key: const Key('enrollment_skip_confirm'),
                            ),
                            IrmaButton(
                              size: IrmaButtonSize.small,
                              minWidth: 0.0,
                              onPressed: () {
                                enterEmail();
                                Navigator.of(context).pop();
                              },
                              label: 'enrollment.provide_email.insert_email',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  minWidth: 0.0,
                  label: 'enrollment.provide_email.skip',
                ),
              ),
              SizedBox(width: IrmaTheme.of(context).defaultSpacing),
              Expanded(
                child: IrmaButton(
                  onPressed: submitEmail,
                  minWidth: 0.0,
                  label: 'enrollment.provide_email.next',
                  key: const Key('enrollment_email_next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
