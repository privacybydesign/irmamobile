import "package:material_ui/material_ui.dart";

import "../../models/error_event.dart";
import "../../sentry/sentry.dart";
import "../../theme/yivi_palette.dart";
import "../../util/i18n.dart";
import "../../widgets/bars/action_bar.dart";
import "../../widgets/bars/app_bar.dart";
import "../../widgets/buttons/pill_buttons.dart";
import "../../widgets/feedback/error_status_screen.dart";
import "../need_help/help_problem.dart";
import "../need_help/need_help_screen.dart";

class ErrorScreen extends StatefulWidget {
  final VoidCallback? onTapClose;
  final VoidCallback? onReportError;

  final ErrorType type;
  final String? details;
  final bool reportable;

  /// When set, "Hulp nodig?" replaces "Send to Yivi" as the button: the user
  /// first gets an answer, and the error report goes along if they end up at
  /// Yivi. Sending the report without asking for help stays possible, as a
  /// link above the details.
  final HelpContext? helpContext;

  /// Instead of the type's heading and text, e.g. to say who caused the
  /// error. Both take [translationParams].
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
    onReportError: reportable
        // One report per error, also when the user mails Yivi support next.
        ? helpContext?.errorReport?.send ??
              () => reportError(details, null, userInitiated: true)
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

  bool get _reported =>
      _hasReported || (widget.helpContext?.errorReport?.sent ?? false);

  void _onTapReport() {
    widget.onReportError?.call();
    setState(() {
      _hasReported = true;
    });
  }

  Future<void> _openHelp() async {
    await openNeedHelp(context, helpContext: widget.helpContext);
    // A mail to Yivi support sent the report along.
    if (mounted) setState(() {});
  }

  /// With "Hulp nodig?" as the button, sending the report is a link.
  Widget? _report(BuildContext context) {
    if (widget.helpContext == null || widget.onReportError == null) {
      return null;
    }
    if (_reported) {
      final palette = YiviPalette.of(context);
      return Text(
        context.tr("error.report_sent"),
        key: const Key("error_report_sent"),
        textAlign: TextAlign.center,
        style: palette.paragraphSmall.copyWith(color: palette.secondaryText),
      );
    }
    return Center(
      child: TextLink(
        key: const Key("error_send_report_link"),
        label: context.tr("error.button_send_report"),
        onPressed: _onTapReport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? tr(String? key) =>
        key == null ? null : context.tr(key, widget.translationParams);
    final help = widget.helpContext;

    return ErrorStatusScreen(
      appBar: YiviAppBar(
        titleTranslationKey: "error.details_title",
        leading: widget.onTapClose != null
            ? YiviBackButton(onTap: widget.onTapClose)
            : null,
      ),
      type: widget.type,
      details: widget.details,
      reportable: widget.reportable,
      title: tr(widget.titleTranslationKey),
      message: tr(widget.bodyTranslationKey),
      report: _report(context),
      actions: ActionBar(
        actions: [
          if (widget.onTapClose != null)
            ActionBar.primary(
              label: context.tr("error.button_ok"),
              onTap: widget.onTapClose,
            ),
          if (help != null)
            ActionBar.secondary(
              label: context.tr("more_tab.need_help"),
              onTap: _openHelp,
            )
          // Once reported, the button stays but cannot be tapped again.
          else if (widget.onReportError != null)
            ActionBar.secondary(
              label: context.tr("error.button_send_to_irma"),
              onTap: _hasReported ? null : _onTapReport,
            ),
        ],
      ),
    );
  }
}
