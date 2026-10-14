import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "../../../providers/pane_selection_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/navigation.dart";
import "../../../util/string.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/irma_avatar.dart";

/// What a log entry is about: who the other party is and what happened.
class ActivitySummary {
  final String title;
  final String subtitleKey;
  final String semanticsKey;
  final IconData icon;
  final LogoImageRef? logo;

  const ActivitySummary({
    required this.title,
    required this.subtitleKey,
    required this.semanticsKey,
    required this.icon,
    this.logo,
  });
}

/// A logo as it comes from the log, without depending on its model class.
class LogoImageRef {
  final String base64;
  final String? mimeType;

  const LogoImageRef(this.base64, this.mimeType);
}

ActivitySummary activitySummary(LogInfo logEntry) {
  switch (logEntry.type) {
    case LogType.removal:
      final first = logEntry.removalLog!.credentials.first;
      return ActivitySummary(
        title: first.issuer.name,
        subtitleKey: "activity.data_deleted",
        semanticsKey: "activity.data_deleted_semantics",
        icon: Icons.delete_outline,
        logo: first.image == null
            ? null
            : LogoImageRef(first.image!.base64, first.image!.mimeType),
      );
    case LogType.issuance:
      final issuer = logEntry.issuanceLog!.issuer;
      return ActivitySummary(
        title: (issuer?.name ?? "").replaceBreakingHyphens(),
        subtitleKey: "activity.data_received",
        semanticsKey: "activity.data_received_semantics",
        icon: Icons.arrow_downward,
        logo: issuer?.image == null
            ? null
            : LogoImageRef(issuer!.image!.base64, issuer.image!.mimeType),
      );
    case LogType.disclosure:
      final verifier = logEntry.disclosureLog!.verifier;
      return ActivitySummary(
        title: (verifier?.name ?? "").replaceBreakingHyphens(),
        subtitleKey: "activity.data_shared",
        semanticsKey: "activity.data_shared_semantics",
        icon: Icons.arrow_upward,
        logo: verifier?.image == null
            ? null
            : LogoImageRef(verifier!.image!.base64, verifier.image!.mimeType),
      );
    case LogType.signature:
      final verifier = logEntry.signedMessageLog!.verifier;
      return ActivitySummary(
        title: (verifier?.name ?? "").replaceBreakingHyphens(),
        subtitleKey: "activity.message_signed",
        semanticsKey: "activity.signed_message_semantics",
        icon: Icons.edit_outlined,
        logo: verifier?.image == null
            ? null
            : LogoImageRef(verifier!.image!.base64, verifier.image!.mimeType),
      );
  }
}

/// One log entry, as a row inside a month group of the Activity tab.
class ActivityCard extends StatelessWidget {
  final LogInfo logEntry;

  /// Draws a divider above the row (all rows but the first of a group).
  final bool showDivider;

  const ActivityCard({required this.logEntry, this.showDivider = false});

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final palette = YiviPalette.of(context);
    final summary = activitySummary(logEntry);
    final timestamp = formatActivityTimestamp(
      context,
      logEntry.time.toLocal(),
      lang,
    );
    final semanticLabel = FlutterI18n.translate(
      context,
      summary.semanticsKey,
      translationParams: {
        "otherParty": summary.title,
        "issuerName": summary.title,
        "date": timestamp,
      },
    );
    final iconColor = switch (logEntry.type) {
      LogType.disclosure => palette.link,
      LogType.issuance => palette.successText,
      LogType.removal => palette.danger,
      LogType.signature => palette.heading,
    };

    return Semantics(
      label: semanticLabel,
      button: true,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => openActivity(context, logEntry),
          child: Container(
            decoration: BoxDecoration(
              border: showDivider
                  ? Border(top: BorderSide(color: palette.divider))
                  : null,
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              spacing: 12,
              children: [
                IrmaAvatar(
                  size: 48,
                  logoImage: summary.logo == null
                      ? null
                      : Base64Image(
                          base64: summary.logo!.base64,
                          mimeType: summary.logo!.mimeType,
                        ),
                  initials: summary.title.isNotEmpty ? summary.title[0] : "?",
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: palette
                            .display(16)
                            .copyWith(color: palette.text),
                      ),
                      Row(
                        spacing: 4,
                        children: [
                          Icon(summary.icon, size: 14, color: iconColor),
                          Flexible(
                            child: Text(
                              FlutterI18n.translate(
                                context,
                                summary.subtitleKey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: palette
                                  .body(14)
                                  .copyWith(color: palette.heading),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 104),
                  child: Text(
                    timestamp,
                    textAlign: TextAlign.right,
                    style: palette.body(12).copyWith(color: palette.heading),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: palette.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String formatActivityTimestamp(
  BuildContext context,
  DateTime time,
  String lang,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final entryDay = DateTime(time.year, time.month, time.day);
  final daysAgo = today.difference(entryDay).inDays;

  if (daysAgo == 0) return DateFormat.jm(lang).format(time);
  if (daysAgo == 1) return FlutterI18n.translate(context, "activity.yesterday");
  return DateFormat.yMMMMd(lang).format(time);
}

/// Opens the details of [logEntry]: in the detail pane in the tablet layout,
/// else on a screen of its own.
void openActivity(BuildContext context, LogInfo logEntry) {
  if (isExpandedLayout(context)) {
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(selectedActivityProvider.notifier).select(logEntry);
    return;
  }
  context.pushActivityDetailsScreen(logInfo: logEntry);
}
