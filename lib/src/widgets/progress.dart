import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';

class IrmaProgress extends StatelessWidget {
  final String description;

  const IrmaProgress(this.description);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: IrmaTheme.of(context).hugeSpacing,
          ),
          LoadingIndicator(),
          SizedBox(
            height: IrmaTheme.of(context).defaultSpacing,
          ),
          Text(
            FlutterI18n.translate(
              context,
              "ui.loading",
            ),
            style: IrmaTheme.of(context).textTheme.display2,
          ),
          SizedBox(
            height: IrmaTheme.of(context).smallSpacing,
          ),
          Text(
            description,
            style: IrmaTheme.of(context).textTheme.body1,
          )
        ],
      ),
    );
  }
}
