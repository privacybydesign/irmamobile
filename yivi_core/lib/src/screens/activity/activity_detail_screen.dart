import "package:flutter_i18n/flutter_i18n.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../theme/yivi_palette.dart";
import "../../widgets/irma_app_bar.dart";
import "widgets/activity_detail_disclosure.dart";
import "widgets/activity_detail_issuance.dart";
import "widgets/activity_detail_removal.dart";

class ActivityDetailsScreenArgs {
  final LogInfo logEntry;

  ActivityDetailsScreenArgs({required this.logEntry});
}

class ActivityDetailsScreen extends StatelessWidget {
  final LogInfo logEntry;

  ActivityDetailsScreen({required ActivityDetailsScreenArgs args})
    : logEntry = args.logEntry;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final dateAtTime = activityDateAtTime(context, logEntry);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: IrmaAppBar(
        title: Text(
          dateAtTime,
          textAlign: TextAlign.center,
          style: palette.display(16).copyWith(color: palette.text),
        ),
      ),
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: SafeArea(child: ActivityDetailContent(logEntry: logEntry)),
        ),
      ),
    );
  }
}

/// The "date at time" title of [logEntry], the title of its detail view.
String activityDateAtTime(BuildContext context, LogInfo logEntry) {
  final lang = FlutterI18n.currentLocale(context)!.languageCode;
  final localTime = logEntry.time.toLocal();
  return FlutterI18n.translate(
    context,
    "credential.date_at_time",
    translationParams: {
      "date": DateFormat.yMMMMd(lang).format(localTime),
      "time": DateFormat.jm(lang).format(localTime),
    },
  );
}

/// What happened in [logEntry]: the body of [ActivityDetailsScreen], also
/// shown in the detail pane of the tablet layout.
class ActivityDetailContent extends StatelessWidget {
  final LogInfo logEntry;

  const ActivityDetailContent({super.key, required this.logEntry});

  @override
  Widget build(BuildContext context) => switch (logEntry.type) {
    LogType.disclosure ||
    LogType.signature => ActivityDetailDisclosure(logEntry: logEntry),
    LogType.issuance => ActivityDetailIssuance(logEntry: logEntry),
    LogType.removal => ActivityDetailRemoval(logEntry: logEntry),
  };
}

/// The detail pane of the activity tab in the tablet layout.
class ActivityDetailPane extends StatelessWidget {
  final LogInfo logEntry;

  const ActivityDetailPane({super.key, required this.logEntry});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    activityDateAtTime(context, logEntry),
                    style: palette.display(18),
                  ),
                ),
                const SizedBox(height: 16),
                ActivityDetailContent(logEntry: logEntry),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
