import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';
import 'loading_indicator.dart';

class IrmaProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          LoadingIndicator(),
          SizedBox(
            height: IrmaTheme.of(context).defaultSpacing,
          ),
          Text(
            FlutterI18n.translate(
              context,
              'ui.loading',
            ),
            style: theme.textTheme.headline3,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
