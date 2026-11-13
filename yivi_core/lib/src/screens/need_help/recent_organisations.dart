import "../../data/recent_session_parties.dart";
import "../../models/irma_configuration.dart";
import "../../models/log_entry.dart";
import "support_party.dart";

/// An organisation the user recently dealt with.
class RecentOrganisation {
  final SupportParty organisation;

  /// The latest session with it never finished, so it is not in the
  /// activity log.
  final bool unfinished;

  const RecentOrganisation(this.organisation, {required this.unfinished});
}

/// The organisations the user most likely needs help with: those of recent
/// sessions, finished or not, and of the activity log, most recent first.
/// Yivi's own parties are left out; they go to Yivi support anyway.
List<RecentOrganisation> recentOrganisations({
  required List<RecentSessionParty> sessions,
  required List<LogInfo> activity,
  IrmaConfiguration? config,
  int max = 5,
}) {
  final candidates = [
    for (final session in sessions)
      (session.party, session.time, !session.completed),
    for (final entry in activity)
      if (entry.requestor case final party?) (party, entry.time, false),
  ]..sort((a, b) => b.$2.compareTo(a.$2));

  final seen = <String>{};
  final result = <RecentOrganisation>[];
  for (final (party, _, unfinished) in candidates) {
    if (!seen.add(party.id)) continue;
    final org = SupportParty.resolve(party, config);
    if (org == null || org.isYivi) continue;
    result.add(RecentOrganisation(org, unfinished: unfinished));
    if (result.length == max) break;
  }
  return result;
}
