// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';

class UpdatingPin extends StatelessWidget {
  static const String routeName = 'change_pin/updating_pin';

  final void Function() cancel;

  const UpdatingPin({@required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: IrmaAppBar(
          titleTranslationKey: 'change_pin.confirm_pin.title',
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
                      FlutterI18n.translate(context, 'change_pin.updating_pin.header'),
                      textAlign: TextAlign.center,
                      style: IrmaTheme.of(context).textTheme.headline4,
                    ),
                  ),
                  SizedBox(height: IrmaTheme.of(context).defaultSpacing),
                  Container(
                    constraints: BoxConstraints(maxWidth: IrmaTheme.of(context).defaultSpacing * 20),
                    child: Text(
                      FlutterI18n.translate(context, 'change_pin.updating_pin.details'),
                      textAlign: TextAlign.center,
                      style: IrmaTheme.of(context).textTheme.bodyText2,
                    ),
                  ),
                ]))));
  }
}
