import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/error/no_internet.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback retryCallback;

  const NoInternetScreen(this.retryCallback);

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
      ),
      body: NoInternet(retryCallback),
    );
  }
}
