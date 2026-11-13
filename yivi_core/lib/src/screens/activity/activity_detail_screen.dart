import "package:flutter_i18n/flutter_i18n.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/theme.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/translated_text.dart";
import "../more/widgets/tiles.dart";
import "../more/widgets/tiles_card.dart";
import "../need_help/help_problem.dart";
import "../need_help/need_help_screen.dart";
import "../need_help/support_party.dart";
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
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final localTime = logEntry.time.toLocal();
    final dateAtTime = FlutterI18n.translate(
      context,
      "credential.date_at_time",
      translationParams: {
        "date": DateFormat.yMMMMd(lang).format(localTime),
        "time": DateFormat.jm(lang).format(localTime),
      },
    );

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        title: Text(
          dateAtTime,
          style: theme.themeData.textTheme.displaySmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: theme.dark,
          ),
        ),
      ),
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    return switch (logEntry.type) {
                      LogType.disclosure || LogType.signature =>
                        ActivityDetailDisclosure(logEntry: logEntry),
                      LogType.issuance => ActivityDetailIssuance(
                        logEntry: logEntry,
                      ),
                      LogType.removal => ActivityDetailRemoval(
                        logEntry: logEntry,
                      ),
                    };
                  },
                ),
                ..._buildNeedHelp(context, dateAtTime),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "Hulp nodig?", with this activity as the first option. Questions about
  /// what happens after sharing go to the organisation, not to Yivi.
  List<Widget> _buildNeedHelp(BuildContext context, String when) {
    final theme = IrmaTheme.of(context);
    final org = SupportParty.resolveIn(
      IrmaRepositoryProvider.of(context),
      logEntry.requestor,
    );
    final disclosed =
        logEntry.type == LogType.disclosure ||
        logEntry.type == LogType.signature;
    final helpContext = activityHelpContext(logEntry.type, org, when);

    return [
      if (disclosed && org != null && !org.isYivi) ...[
        SizedBox(height: theme.defaultSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
          child: TranslatedText(
            "need_help.context.activity_disclosure_note",
            translationParams: {"org": org.name},
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.neutralExtraDark,
            ),
          ),
        ),
      ],
      SizedBox(height: theme.defaultSpacing),
      TilesCard(
        children: [
          InternalLinkTile(
            key: const Key("activity_need_help_button"),
            labelTranslationKey: "more_tab.need_help",
            iconData: Icons.support_outlined,
            onTap: () => openNeedHelp(context, helpContext: helpContext),
          ),
        ],
      ),
    ];
  }
}

/// The activity as the first option in "Hulp nodig?", or null when there is
/// nothing about it to ask an organisation.
HelpContext? activityHelpContext(
  LogType type,
  SupportParty? org,
  String when,
) => switch (type) {
  _ when org == null => null,
  // Yivi asked for the data itself: no outcome waits at an organisation.
  LogType.disclosure || LogType.signature when org.isYivi => null,
  LogType.disclosure || LogType.signature => HelpContext(
    sectionKey: "need_help.context.activity_section",
    labelKey: "need_help.context.activity_disclosure",
    subtitle: when,
    problem: HelpProblems.outcome,
    organisation: org,
  ),
  LogType.issuance => HelpContext(
    sectionKey: "need_help.context.activity_section",
    labelKey: "need_help.context.activity_issuance",
    subtitle: when,
    // Yivi's own data (email, phone number) is Yivi's to fix.
    problem: org.isYivi
        ? HelpProblems.dataWrong
        : HelpProblems.dataFromOrganisation,
    organisation: org,
  ),
  LogType.removal => null,
};
