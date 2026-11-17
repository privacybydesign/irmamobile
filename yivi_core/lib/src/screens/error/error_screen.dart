import "package:material_ui/material_ui.dart";

import "../../models/error_event.dart";
import "../../sentry/sentry.dart";
import "../../util/i18n.dart";
import "../../widgets/action_bar.dart";
import "../../widgets/error_status_screen.dart";
import "../../widgets/irma_app_bar.dart";

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
  }) => ErrorScreen._(
    onTapClose: onTapClose,
    type: type,
    details: details,
    reportable: reportable,
    onReportError: reportable
        ? () => reportError(details, null, userInitiated: true)
        : null,
  );

  /// Display an error screen for an ErrorEvent. The user can choose to report the error to Sentry.
  factory ErrorScreen.fromEvent({
    VoidCallback? onTapClose,
    required ErrorEvent error,
    bool reportable = true,
  }) => ErrorScreen._(
    // Fatal events are unrecoverable, so closing the error is not possible.
    onTapClose: error.fatal ? null : onTapClose,
    type: ErrorType.general,
    details: error.toString(),
    reportable: reportable,
    onReportError: () =>
        reportError(error.exception, error.stack, userInitiated: true),
  );

  const ErrorScreen._({
    this.onTapClose,
    this.onReportError,
    required this.type,
    this.details,
    required this.reportable,
  }) : super(key: const ValueKey("error_screen"));

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
    return ErrorStatusScreen(
      appBar: IrmaAppBar(
        titleTranslationKey: "error.details_title",
        leading: widget.onTapClose != null
            ? YiviBackButton(onTap: widget.onTapClose)
            : null,
      ),
      type: widget.type,
      details: widget.details,
      reportable: widget.reportable,
      actions: ActionBar(
        actions: [
          if (widget.onTapClose != null)
            ActionBar.primary(
              label: context.tr("error.button_ok"),
              onTap: widget.onTapClose,
            ),
          // Once reported, the button stays but cannot be tapped again.
          if (widget.onReportError != null)
            ActionBar.secondary(
              label: context.tr("error.button_send_to_irma"),
              onTap: _hasReported ? null : _onTapReport,
            ),
        ],
      ),
    );
  }
}
