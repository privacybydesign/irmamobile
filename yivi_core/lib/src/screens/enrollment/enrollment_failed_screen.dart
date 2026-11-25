import "package:material_ui/material_ui.dart";

import "../../models/session.dart";
import "../../util/i18n.dart";
import "../../widgets/bars/action_bar.dart";
import "../../widgets/bars/app_bar.dart";
import "../../widgets/feedback/error_status_screen.dart";

/// Setting up the app failed: says why, in a sentence with the actual reason
/// ([enrollmentFailureReason]), with the full error behind "Show technical
/// details" to read or copy. Without internet it says that instead.
class EnrollmentFailedScreen extends StatelessWidget {
  final SessionError error;
  final VoidCallback onPrevious;
  final VoidCallback onRetryEnrollment;

  const EnrollmentFailedScreen({
    super.key,
    required this.error,
    required this.onPrevious,
    required this.onRetryEnrollment,
  });

  @override
  Widget build(BuildContext context) {
    final offline = error.errorType == "transport";
    return ErrorStatusScreen(
      appBar: YiviAppBar(
        titleTranslationKey: "ui.error",
        leading: YiviBackButton(onTap: onPrevious),
      ),
      actions: ActionBar.single(
        label: context.tr("ui.retry"),
        onTap: onRetryEnrollment,
      ),
      type: ErrorType.general,
      title: offline ? context.tr("error.no_internet_title") : null,
      message: offline
          ? context.tr("error.types.no_internet")
          : context.tr("enrollment.failed.message", {
              "reason": enrollmentFailureReason(error),
            }),
      details: error.toString(),
    );
  }
}

/// The most telling part of [error], in a line: what the server said, else
/// the error underneath, else what it is about, else its kind.
String enrollmentFailureReason(SessionError error) {
  final remote = error.remoteError;
  for (final text in [
    remote?.description,
    remote?.message,
    remote?.errorName,
    error.wrappedError,
    error.info,
    error.errorType,
  ]) {
    final t = text?.trim() ?? "";
    if (t.isNotEmpty) return t;
  }
  return "";
}
