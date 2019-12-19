import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/cancel_button.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

class EnterPin extends StatelessWidget {
  static const String routeName = 'change_pin/enter_pin';

  final void Function(String) submitOldPin;
  final void Function() cancel;
  final FocusNode pinFocusNode;

  const EnterPin({@required this.pinFocusNode, @required this.submitOldPin, @required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: IrmaTheme.of(context).grayscale85,
        leading: CancelButton(cancel: cancel),
        title: Text(
          FlutterI18n.translate(context, 'change_pin.enter_pin.title'),
          style: IrmaTheme.of(context).textTheme.display2,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).defaultSpacing),
          child: Column(
            children: [
              SizedBox(height: IrmaTheme.of(context).hugeSpacing),
              Text(
                FlutterI18n.translate(context, 'change_pin.enter_pin.instruction'),
                style: IrmaTheme.of(context).textTheme.body1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: IrmaTheme.of(context).mediumSpacing),
              PinField(
                focusNode: pinFocusNode,
                maxLength: 5,
                onSubmit: (String pin) {
                  // TODO: show loading screen
                  submitOldPin(pin);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
