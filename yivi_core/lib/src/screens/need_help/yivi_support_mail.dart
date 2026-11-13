import "dart:io";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";
import "package:package_info_plus/package_info_plus.dart";

import "../../../sentry_dsn.dart";
import "../../providers/irma_repository_provider.dart";
import "../../sentry/sentry.dart";
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
  final repo = IrmaRepositoryProvider.of(context);
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

  if (errorReport != null && errorReport.reportable) {
    reportError(errorReport.details, null, userInitiated: true);
  }

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

  // Uri(queryParameters:) encodes spaces as "+", which mail apps show as is.
  final mail =
      "mailto:$address"
      "?subject=${Uri.encodeComponent(subject)}"
      "&body=${Uri.encodeComponent(body)}";

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
