import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/error_event.dart';
import 'package:irmamobile/src/screens/error/error_details.dart';
import 'package:irmamobile/src/sentry/sentry.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';

enum ErrorType {
  general,
  expired,
  pairingRejected,
}

class ErrorScreen extends StatefulWidget {
  final VoidCallback onTapClose;
  final VoidCallback onReportError;

  final ErrorType type;
  final String details;
  final bool reportable;

  /// Display an error screen. The user can optionally choose to report those error details to Sentry.
  factory ErrorScreen({
    @required VoidCallback onTapClose,
    ErrorType type = ErrorType.general,
    String details,
    bool reportable = true,
  }) =>
      ErrorScreen._(
        onTapClose: onTapClose,
        type: type,
        details: details,
        reportable: reportable,
        onReportError: reportable ? () => reportError(details, null, userInitiated: true) : null,
      );

  /// Display an error screen for an ErrorEvent. The user can choose to report the error to Sentry.
  factory ErrorScreen.fromEvent({@required VoidCallback onTapClose, ErrorEvent error}) => ErrorScreen._(
        // Fatal events are unrecoverable, so closing the error is not possible.
        onTapClose: error.fatal ? null : onTapClose,
        type: ErrorType.general,
        details: error.toString(),
        reportable: true,
        onReportError: () => reportError(error.exception, error.stack, userInitiated: true),
      );

  const ErrorScreen._({this.onTapClose, this.onReportError, this.type, this.details, this.reportable});

  @override
  State<StatefulWidget> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  bool _hasReported = false;

  void _onTapReport() {
    widget.onReportError();
    setState(() {
      _hasReported = true;
    });
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
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
            noLeading: widget.onTapClose == null,
            leadingAction: widget.onTapClose,
          ),
          body: ErrorDetails(
            type: widget.type,
            details: widget.details,
            reportable: widget.reportable,
          ),
          bottomNavigationBar: IrmaBottomBar(
            primaryButtonLabel: widget.onTapClose != null ? FlutterI18n.translate(context, 'error.button_ok') : null,
            onPrimaryPressed: widget.onTapClose,
            // If the error has been reported, the secondary button should be disabled, but the label should remain visible.
            secondaryButtonLabel:
                widget.onReportError != null ? FlutterI18n.translate(context, 'error.button_send_to_irma') : null,
            onSecondaryPressed: widget.onReportError != null && !_hasReported ? _onTapReport : null,
          ),
        ),
      );
}
