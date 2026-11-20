import "dart:io";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";
import "package:package_info_plus/package_info_plus.dart";

import "../../../sentry_dsn.dart";
import "../../providers/irma_repository_provider.dart";
import "../../widgets/irma_dialog.dart";
import "../../widgets/yivi_themed_button.dart";
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
  String t(String key, [Map<String, String>? params]) =>
      FlutterI18n.translate(context, key, translationParams: params);

  final address = t("help.contact");
  final subject = t("need_help.yivi.mail_subject", {"topic": topic});
  final prompt = t("need_help.yivi.mail_prompt");
  final topicLabel = t("need_help.yivi.mail_topic");
  final versionLabel = t("need_help.yivi.mail_app_version");
  final deviceLabel = t("need_help.yivi.mail_device");
  final reportLabel = t("need_help.yivi.mail_error_report");
  final errorTitle = t("help.mail_error_title");
  final errorBody = t("help.mail_error");

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
    if (report != null) ...[
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
    errorTitle: errorTitle,
    errorBody: errorBody,
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
}) {
  String t(String key, [Map<String, String>? params]) =>
      FlutterI18n.translate(context, key, translationParams: params);

  return _openMail(
    context,
    mailtoUri(
      address: email,
      subject: t("need_help.yivi.mail_subject", {"topic": topic}),
      body: organisationMailBody(
        prompt: t("need_help.yivi.mail_prompt"),
        topicLabel: t("need_help.yivi.mail_topic"),
        topic: topic,
        errorCodeLabel: t("need_help.organisation.mail_error_code"),
        errorCode: errorCode,
        sentFrom: t("need_help.organisation.mail_sent_from"),
      ),
    ),
    errorTitle: t("help.mail_error_title"),
    errorBody: t("help.mail_error"),
  );
}

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

Future<void> _openMail(
  BuildContext context,
  String mail, {
  required String errorTitle,
  required String errorBody,
}) async {
  final repo = IrmaRepositoryProvider.of(context);
  try {
    await repo.openURLExternally(mail);
  } catch (_) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => IrmaDialog(
        title: errorTitle,
        content: errorBody,
        child: YiviThemedButton(
          label: "help.mail_error_button",
          onPressed: () => Navigator.pop(context),
        ),
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
