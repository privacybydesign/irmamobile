import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/i18n.dart";
import "../../widgets/surfaces/list_row.dart";
import "../../widgets/surfaces/surface_card.dart";
import "help_problem.dart";
import "need_help_screen.dart";
import "support_party.dart";

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

/// "Hulp nodig?" under an activity's details, with the activity as the
/// first option. Questions about what happens after sharing go to the
/// organisation, not to Yivi: after a share that is said first.
class ActivityNeedHelp extends StatelessWidget {
  final LogInfo log;

  const ActivityNeedHelp({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final org = SupportParty.resolve(log.requestor, null);
    final disclosed =
        log.type == LogType.disclosure || log.type == LogType.signature;
    final when = DateFormat.yMMMMd(
      context.lang,
    ).add_Hm().format(log.time.toLocal());
    final helpContext = activityHelpContext(log.type, org, when);

    return Padding(
      padding: const EdgeInsets.only(top: YiviSpace.x24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: YiviSpace.x12,
        children: [
          if (disclosed && org != null && !org.isYivi)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x4),
              child: Text(
                context.tr("need_help.context.activity_disclosure_note", {
                  "org": org.name,
                }),
                style: palette.paragraphSmall.copyWith(
                  color: palette.secondaryText,
                ),
              ),
            ),
          SurfaceCard(
            clipBehavior: Clip.antiAlias,
            child: ListRow(
              key: const Key("activity_need_help_button"),
              leading: Icon(
                Icons.support_outlined,
                size: 20,
                color: palette.link,
              ),
              title: context.tr("more_tab.need_help"),
              dense: true,
              onTap: () => openNeedHelp(context, helpContext: helpContext),
            ),
          ),
        ],
      ),
    );
  }
}
