import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/error/general_error.dart';
import 'package:irmamobile/src/sentry/sentry.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class GeneralErrorScreen extends StatelessWidget {
  final String errorText;
  final VoidCallback onTapClose;
  final VoidCallback onTapReport;

  const GeneralErrorScreen({@required this.errorText, @required this.onTapClose, this.onTapReport});

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
      body: GeneralError(
          errorText: errorText,
          onTapClose: onTapClose,
          onTapReport: onTapReport ??
              () {
                // There is no sensible stack trace to pass here, so the exception will
                // have to do.
                reportError(errorText, null);
              }),
    );
  }
}
