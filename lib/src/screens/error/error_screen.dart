import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/error_event.dart';
import '../../sentry/sentry.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_error_scaffold_body.dart';

class ErrorScreen extends StatefulWidget {
  final VoidCallback? onTapClose;
  final VoidCallback? onReportError;

  final ErrorType type;
  final String? details;
  final bool reportable;

  /// Display an error screen. The user can optionally choose to report those error details to Sentry.
  factory ErrorScreen({
    required VoidCallback onTapClose,
    ErrorType type = ErrorType.general,
    String? details,
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
  factory ErrorScreen.fromEvent({VoidCallback? onTapClose, required ErrorEvent error, bool reportable = true}) =>
      ErrorScreen._(
        // Fatal events are unrecoverable, so closing the error is not possible.
        onTapClose: error.fatal ? null : onTapClose,
        type: ErrorType.general,
        details: error.toString(),
        reportable: reportable,
        onReportError: () => reportError(error.exception, error.stack, userInitiated: true),
      );

  const ErrorScreen._({
    this.onTapClose,
    this.onReportError,
    required this.type,
    this.details,
    required this.reportable,
  }) : super(key: const ValueKey('error_screen'));

  @override
  State<StatefulWidget> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  bool _hasReported = false;

  void _onTapReport() {
    widget.onReportError?.call();
    setState(() {
      _hasReported = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, popResult) {
        widget.onTapClose?.call();
      },
      child: Scaffold(
        appBar: IrmaAppBar(
          titleTranslationKey: 'error.details_title',
          leading: widget.onTapClose != null ? YiviBackButton(onTap: widget.onTapClose) : null,
        ),
        body: IrmaErrorScaffoldBody(
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
}
