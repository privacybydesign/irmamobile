import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class ConfirmDenyDialog extends StatelessWidget {
  const ConfirmDenyDialog({
    @required this.title,
    @required this.content,
    @required this.confirmContent,
    @required this.denyContent
  });

  final String title;
  final String content;
  final String confirmContent;
  final String denyContent;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
      child: Container(
        height: 246.0,
        padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Flexible(
              child: Padding(
                padding: EdgeInsets.only(bottom: IrmaTheme.of(context).defaultSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.display2,
                    ),
                    SizedBox(height: IrmaTheme.of(context).tinySpacing),
                    Text(
                      content,
                      style: Theme.of(context).textTheme.body1,
                      ),
                  ],
                ),
              ),
            ),
            Row(
              children: <Widget>[
                IrmaTextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  label: denyContent,
                  minWidth: 0,
                ),
                IrmaButton(
                  size: IrmaButtonSize.small,
                  onPressed: () => Navigator.of(context).pop(true),
                  label: confirmContent,
                  minWidth: 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
