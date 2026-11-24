import "dart:io";

import "package:material_ui/material_ui.dart";
import "package:package_info_plus/package_info_plus.dart";

import "../../../sentry_dsn.dart";
import "../../providers/irma_repository_provider.dart";
import "../../util/i18n.dart";
import "../../widgets/buttons/pill_buttons.dart";
import "../../widgets/feedback/dialog.dart";
import "help_problem.dart";

/// Long stack traces make the mailto link too long for some mail apps.
const _maxReportLength = 1500;

/// Opens the user's mail app with a mail to Yivi support. The subject names
/// the problem; the body asks for a description and adds the app version,
/// the device and, after an error, the error report.
Future<void> mailYiviSupport(
  BuildContext context, {
  required String topic,
  HelpErrorReport? errorReport,
}) async {
  final address = context.tr("help.contact");
  final subject = context.tr("need_help.yivi.mail_subject", {"topic": topic});
  final prompt = context.tr("need_help.yivi.mail_prompt");
  final topicLabel = context.tr("need_help.yivi.mail_topic");
  final versionLabel = context.tr("need_help.yivi.mail_app_version");
  final deviceLabel = context.tr("need_help.yivi.mail_device");
  final reportLabel = context.tr("need_help.yivi.mail_error_report");

  errorReport?.send();

  final report = errorReport?.details;
  final body = [
    prompt,
    "",
    "",
    "",
    "---",
    "$topicLabel: $topic",
    "$versionLabel: ${await _appVersion()}",
    "$deviceLabel: ${Platform.operatingSystem} "
        "${Platform.operatingSystemVersion}",
    if (report != null && report.isNotEmpty) ...[
      "",
      "$reportLabel:",
      report.length > _maxReportLength
          ? "${report.substring(0, _maxReportLength)}…"
          : report,
    ],
  ].join("\n");

  if (!context.mounted) return;
  await _openMail(
    context,
    mailtoUri(address: address, subject: subject, body: body),
  );
}

/// Opens the user's mail app with a mail to an organisation's own support.
/// The subject names the problem; the body asks for a description and adds
/// the error code when there is one. The error report stays out: that is
/// about the app, and only of use to Yivi support.
Future<void> mailOrganisation(
  BuildContext context, {
  required String email,
  required String topic,
  String? errorCode,
}) => _openMail(
  context,
  mailtoUri(
    address: email,
    subject: context.tr("need_help.yivi.mail_subject", {"topic": topic}),
    body: organisationMailBody(
      prompt: context.tr("need_help.yivi.mail_prompt"),
      topicLabel: context.tr("need_help.yivi.mail_topic"),
      topic: topic,
      errorCodeLabel: context.tr("need_help.organisation.mail_error_code"),
      errorCode: errorCode,
      sentFrom: context.tr("need_help.organisation.mail_sent_from"),
    ),
  ),
);

/// The body of a mail to an organisation: room to describe the problem,
/// then what the organisation needs to place the request.
String organisationMailBody({
  required String prompt,
  required String topicLabel,
  required String topic,
  required String errorCodeLabel,
  required String sentFrom,
  String? errorCode,
}) => [
  prompt,
  "",
  "",
  "",
  "---",
  "$topicLabel: $topic",
  if (errorCode != null) "$errorCodeLabel: $errorCode",
  sentFrom,
].join("\n");

/// Uri(queryParameters:) encodes spaces as "+", which mail apps show as is.
String mailtoUri({
  required String address,
  required String subject,
  required String body,
}) =>
    "mailto:$address"
    "?subject=${Uri.encodeComponent(subject)}"
    "&body=${Uri.encodeComponent(body)}";

/// Opens [mail], or explains in a dialog that no mail app could be opened.
Future<void> _openMail(BuildContext context, String mail) async {
  try {
    await browserOf(context).openExternally(mail);
  } catch (_) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => YiviDialog(
        title: context.tr("help.mail_error_title"),
        message: context.tr("help.mail_error"),
        actions: [
          PrimaryPillButton(
            label: context.tr("help.mail_error_button"),
            size: PillSize.regular,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

Future<String> _appVersion() async {
  final build = version.length > 8 ? version.substring(0, 8) : version;
  try {
    final info = await PackageInfo.fromPlatform();
    return "${info.version} (${info.buildNumber}, $build)";
  } catch (_) {
    return build;
  }
}
