import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:rxdart/rxdart.dart";

import "../../models/log_entry.dart";
import "../../models/scheme_rules.dart";
import "../../models/support_directory.dart";
import "../../providers/irma_repository_provider.dart";
import "recent_organisations.dart";

/// Where the organisations in the schemes offer support. Asked from the
/// bridge while "Need help?" is open, and again after every
/// [SchemeRulesEvent] (Go sends one after each scheme change).
final supportDirectoryProvider = StreamProvider.autoDispose<SupportDirectory>((
  ref,
) {
  final repo = ref.watch(irmaRepositoryProvider);
  void ask() => repo.bridgedDispatch(RequestSupportDirectoryEvent());

  final asks = repo.getEvents().whereType<SchemeRulesEvent>().listen(
    (_) => ask(),
  );
  ref.onDispose(asks.cancel);
  // Asked once listened to, so the answer cannot come before the listener.
  return repo
      .getEvents()
      .whereType<SupportDirectoryEvent>()
      .map((event) => event.directory)
      .doOnListen(ask);
});

/// The latest entries of the activity log, for the organisations the user
/// recently dealt with.
final _recentActivityProvider = FutureProvider.autoDispose<List<LogInfo>>((
  ref,
) async {
  final log = ref.watch(activityLogClientProvider);
  final page = await log.queryLogs(const LogQuery(limit: 20));
  return page.entries;
});

/// The organisations the user most likely needs help with. Sessions from
/// memory show right away; the activity log and the scheme join once they
/// have loaded.
final recentOrganisationsProvider =
    Provider.autoDispose<List<RecentOrganisation>>((ref) {
      final repo = ref.watch(irmaRepositoryProvider);
      return recentOrganisations(
        sessions: repo.sessions.recentParties.recent,
        activity: ref.watch(_recentActivityProvider).value ?? const [],
        directory: ref.watch(supportDirectoryProvider).value,
      );
    });
