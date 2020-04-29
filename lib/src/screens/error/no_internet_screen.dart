import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/error/no_internet.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback onTapClose;
  final VoidCallback onTapRetry;

  const NoInternetScreen({@required this.onTapClose, this.onTapRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(
            context,
            'error.title',
          ),
        ),
        leadingAction: onTapClose,
      ),
      body: NoInternet(),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, 'error.button_back'),
        onPrimaryPressed: onTapClose,
        secondaryButtonLabel: onTapRetry == null ? null : FlutterI18n.translate(context, 'error.button_retry'),
        onSecondaryPressed: onTapRetry,
      ),
    );
  }
}
