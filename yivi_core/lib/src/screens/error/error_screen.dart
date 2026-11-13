import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../models/error_event.dart";
import "../../sentry/sentry.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_error_scaffold_body.dart";
import "../need_help/help_problem.dart";
import "../need_help/need_help_screen.dart";

class ErrorScreen extends StatefulWidget {
  final VoidCallback? onTapClose;
  final VoidCallback? onReportError;

  final ErrorType type;
  final String? details;
  final bool reportable;

  /// When set, "Hulp nodig?" replaces "Send to Yivi": the user first gets
  /// an answer, and the error report goes along if they end up at Yivi.
  final HelpContext? helpContext;
  final String? titleTranslationKey;
  final String? bodyTranslationKey;
  final Map<String, String>? translationParams;

  /// Display an error screen. The user can optionally choose to report those error details to Sentry.
  factory ErrorScreen({
    required VoidCallback onTapClose,
    ErrorType type = ErrorType.general,
    String? details,
    bool reportable = true,
    HelpContext? helpContext,
    String? titleTranslationKey,
    String? bodyTranslationKey,
    Map<String, String>? translationParams,
  }) => ErrorScreen._(
    onTapClose: onTapClose,
    type: type,
    details: details,
    reportable: reportable,
    onReportError: reportable && helpContext == null
        ? () => reportError(details, null, userInitiated: true)
        : null,
    helpContext: helpContext,
    titleTranslationKey: titleTranslationKey,
    bodyTranslationKey: bodyTranslationKey,
    translationParams: translationParams,
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
    this.helpContext,
    this.titleTranslationKey,
    this.bodyTranslationKey,
    this.translationParams,
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

  String? _secondaryLabel(BuildContext context) {
    if (widget.helpContext != null) {
      return FlutterI18n.translate(context, "more_tab.need_help");
    }
    return widget.onReportError != null
        ? FlutterI18n.translate(context, "error.button_send_to_irma")
        : null;
  }

  VoidCallback? _onSecondaryPressed(BuildContext context) {
    final help = widget.helpContext;
    if (help != null) return () => openNeedHelp(context, helpContext: help);
    // Once reported, the button stays visible but disabled.
    return widget.onReportError != null && !_hasReported ? _onTapReport : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: "error.details_title",
        leading: widget.onTapClose != null
            ? YiviBackButton(onTap: widget.onTapClose)
            : null,
      ),
      body: IrmaErrorScaffoldBody(
        type: widget.type,
        details: widget.details,
        reportable: widget.reportable,
        titleTranslationKey: widget.titleTranslationKey,
        bodyTranslationKey: widget.bodyTranslationKey,
        translationParams: widget.translationParams,
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: widget.onTapClose != null
            ? FlutterI18n.translate(context, "error.button_ok")
            : null,
        onPrimaryPressed: widget.onTapClose,
        secondaryButtonLabel: _secondaryLabel(context),
        onSecondaryPressed: _onSecondaryPressed(context),
      ),
    );
  }
}
