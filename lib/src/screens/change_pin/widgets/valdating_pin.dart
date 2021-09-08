// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';

class ValidatingPin extends StatelessWidget {
  static const String routeName = 'change_pin/validating_pin';

  final void Function() cancel;

  const ValidatingPin({@required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: IrmaAppBar(
          title: Text(
            FlutterI18n.translate(context, 'change_pin.confirm_pin.title'),
          ),
          leadingAction: () async {
            if (cancel != null) {
              cancel();
            }
            if (!await Navigator.of(context).maybePop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          leadingTooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        ),
        body: SingleChildScrollView(
            child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(top: IrmaTheme.of(context).largeSpacing),
                child: Column(children: [
                  SizedBox(height: IrmaTheme.of(context).hugeSpacing),
                  LoadingIndicator(),
                  SizedBox(height: IrmaTheme.of(context).largeSpacing),
                  Container(
                    constraints: BoxConstraints(maxWidth: IrmaTheme.of(context).defaultSpacing * 16),
                    child: Text(
                      FlutterI18n.translate(context, 'change_pin.validating_pin.header'),
                      textAlign: TextAlign.center,
                      style: IrmaTheme.of(context).textTheme.display1,
                    ),
                  ),
                  SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                  Container(
                    constraints: BoxConstraints(maxWidth: IrmaTheme.of(context).defaultSpacing * 20),
                    child: Text(
                      FlutterI18n.translate(context, 'change_pin.validating_pin.details'),
                      textAlign: TextAlign.center,
                      style: IrmaTheme.of(context).textTheme.body1,
                    ),
                  ),
                ]))));
  }
}
