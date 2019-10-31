import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/reset_pin/widgets/cancel_button.dart';
import 'package:irmamobile/src/theme/irma-icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/link_button.dart';
import 'package:irmamobile/src/widgets/primary_button.dart';

class ResetPinScreen extends StatelessWidget {
  void cancel(BuildContext context) {
    Navigator.of(context).pop();
  }

  void confirm(BuildContext context) {
    IrmaRepository.get().enroll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CancelButton(cancel: cancel),
        title: Text(FlutterI18n.translate(context, 'reset_pin.title')),
      ),
      body: SingleChildScrollView(
          padding: EdgeInsets.only(top: IrmaTheme.of(context).spacing * 2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Center(child: const Icon(IrmaIcons.lock, size: 180)),
            SizedBox(height: IrmaTheme.of(context).spacing),
            Container(
                constraints: BoxConstraints(maxWidth: IrmaTheme.of(context).spacing * 16),
                child: Text(
                  FlutterI18n.translate(context, 'reset_pin.message'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.body2,
                )),
            SizedBox(height: IrmaTheme.of(context).spacing),
            Container(
                constraints: BoxConstraints(maxWidth: IrmaTheme.of(context).spacing * 16),
                child: Text(
                  FlutterI18n.translate(context, 'reset_pin.existing_data_title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline,
                )),
            SizedBox(height: IrmaTheme.of(context).spacing),
            Container(
                constraints: BoxConstraints(maxWidth: IrmaTheme.of(context).spacing * 16),
                child: Text(
                  FlutterI18n.translate(context, 'reset_pin.existing_data_message'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.body2,
                )),
            SizedBox(height: IrmaTheme.of(context).spacing),
            Wrap(
              runSpacing: IrmaTheme.of(context).spacing,
              spacing: IrmaTheme.of(context).spacing,
              children: <Widget>[
                LinkButton(
                  onPressed: () => cancel(context),
                  label: 'reset_pin.back',
                ),
                Column(
                  children: <Widget>[
                    PrimaryButton(
                      onPressed: () => confirm(context),
                      label: 'reset_pin.reset',
                    ),
                    Text(
                      FlutterI18n.translate(context, 'reset_pin.existing_data_removed'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.body1,
                    )
                  ],
                ),
              ],
            )
          ])),
    );
  }
}
