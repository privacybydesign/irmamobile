import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/error/general_error.dart';
import 'package:irmamobile/src/sentry/sentry.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';

class GeneralErrorScreen extends StatefulWidget {
  final String errorText;
  final VoidCallback onTapClose;
  final VoidCallback onTapReport;

  const GeneralErrorScreen({@required this.errorText, this.onTapClose, this.onTapReport});

  @override
  State<GeneralErrorScreen> createState() => _GeneralErrorScreenState();
}

class _GeneralErrorScreenState extends State<GeneralErrorScreen> {
  bool hasReported = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.onTapClose != null) widget.onTapClose();
        return false;
      },
      child: Scaffold(
        appBar: IrmaAppBar(
          title: Text(
            FlutterI18n.translate(
              context,
              'error.title',
            ),
          ),
          leadingAction: widget.onTapClose,
        ),
        body: GeneralError(
          errorText: widget.errorText,
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: widget.onTapClose != null ? FlutterI18n.translate(context, 'error.button_ok') : null,
          onPrimaryPressed: widget.onTapClose,
          secondaryButtonLabel: FlutterI18n.translate(context, 'error.button_send_to_irma'),
          onSecondaryPressed: hasReported
              ? null
              : () {
                  if (widget.onTapReport != null) {
                    widget.onTapReport();
                  } else {
                    // There is no sensible stack trace to pass here, so the exception will
                    // have to do.
                    reportError(widget.errorText, null, userInitiated: true);
                  }
                  setState(() {
                    hasReported = true;
                  });
                },
        ),
      ),
    );
  }
}
