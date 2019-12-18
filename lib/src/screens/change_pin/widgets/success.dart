import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/screens/change_pin/widgets/cancel_button.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

class Success extends StatelessWidget {
  static const String routeName = 'change_pin/success';

  final void Function() cancel;

  const Success({@required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: IrmaTheme.of(context).grayscale85,
        leading: CancelButton(cancel: cancel),
        title: Text(
          FlutterI18n.translate(context, 'change_pin.confirm_pin.title'),
          style: IrmaTheme.of(context).textTheme.display2,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: IrmaTheme.of(context).hugeSpacing),

              // TODO: This should be added as an icon to the IrmaIcon font
              SvgPicture.asset('assets/generic/check.svg'),

              SizedBox(height: IrmaTheme.of(context).largeSpacing),
              Text(
                FlutterI18n.translate(context, 'change_pin.success.title'),
                style: IrmaTheme.of(context).textTheme.display2,
              ),
              SizedBox(height: IrmaTheme.of(context).smallSpacing),
              Text(
                FlutterI18n.translate(context, 'change_pin.success.message'),
                style: IrmaTheme.of(context).textTheme.body1,
              ),
              SizedBox(height: IrmaTheme.of(context).hugeSpacing),
              IrmaButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                label: 'change_pin.success.continue',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
