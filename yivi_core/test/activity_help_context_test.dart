import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/need_help/help_problem.dart";
import "package:yivi_core/src/screens/need_help/support_party.dart";

SupportParty _org(String id, String name, {bool isYivi = false}) =>
    SupportParty(
      party: TrustedParty(
        id: id,
        name: name,
        url: null,
        parent: null,
        verified: true,
      ),
      isYivi: isYivi,
    );

void main() {
  final cis = _org("pbdf-requestors.cis", "Stichting CIS");
  final yivi = _org("pbdf-requestors.pbdf", "Yivi", isYivi: true);

  test("sharing with an organisation: ask about the outcome there", () {
    for (final type in [LogType.disclosure, LogType.signature]) {
      final context = activityHelpContext(type, cis, "today")!;
      expect(context.problem, HelpProblems.outcome);
      expect(context.organisation, cis);
    }
  });

  test("sharing with Yivi itself offers no outcome to ask about", () {
    // Its answer would say the outcome comes from Yivi, not from Yivi.
    for (final type in [LogType.disclosure, LogType.signature]) {
      expect(activityHelpContext(type, yivi, "today"), isNull);
    }
  });

  test("data from an organisation is its to fix; Yivi's own data Yivi's", () {
    expect(
      activityHelpContext(LogType.issuance, cis, "today")!.problem,
      HelpProblems.dataFromOrganisation,
    );
    expect(
      activityHelpContext(LogType.issuance, yivi, "today")!.problem,
      HelpProblems.dataWrong,
    );
  });

  test("nothing to ask about a removal or an unknown party", () {
    expect(activityHelpContext(LogType.removal, cis, "today"), isNull);
    expect(activityHelpContext(LogType.disclosure, null, "today"), isNull);
  });
}
