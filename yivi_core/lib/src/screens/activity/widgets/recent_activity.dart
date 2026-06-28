import "dart:async";

import "package:flutter/material.dart";

import "../../../models/log_entry.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";
import "../history_repository.dart";
import "activity_card.dart";

class RecentActivity extends StatefulWidget {
  final int amountOfLogs;
  final VoidCallback onTap;

  const RecentActivity({required this.onTap, this.amountOfLogs = 2});

  @override
  State<RecentActivity> createState() => _RecentActivityState();
}

class _RecentActivityState extends State<RecentActivity> {
  late final HistoryRepository _historyRepo;
  late StreamSubscription _repoStateSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // only init the _historyRepo once by trying to access it and initializing when a late init error was thrown
    // we do this because we can't access the build context in initState() and we only want to do it once
    try {
      _historyRepo;
    } catch (_) {
      _loadLogs();
      _historyRepo = HistoryRepository(IrmaRepositoryProvider.of(context));
      // TODO: listen for session success to refresh logs
      _repoStateSubscription = IrmaRepositoryProvider.of(
        context,
      ).getEvents().listen((event) {});
    }
  }

  @override
  void dispose() {
    _historyRepo.dispose();
    _repoStateSubscription.cancel();
    super.dispose();
  }

  void _loadLogs() {
    IrmaRepositoryProvider.of(
      context,
    ).bridgedDispatch(LoadLogsEvent(max: widget.amountOfLogs));
  }

  /// Returns at most [count] entries, newest first and de-duplicated. The
  /// underlying [HistoryState] can hold a varying number of (possibly
  /// repeated) entries because [HistoryRepository] accumulates every
  /// [LogsEvent] from the shared event bus, so we bound and order the list
  /// here to keep the displayed count stable across navigation.
  static List<LogInfo> _mostRecentEntries(List<LogInfo> entries, int count) {
    final seen = <DateTime>{};
    final deduplicated = <LogInfo>[];
    for (final entry in entries) {
      // Log entries are timestamped with microsecond precision, so the time
      // uniquely identifies an entry; this drops duplicates introduced by
      // accumulating overlapping LogsEvent batches.
      if (seen.add(entry.time)) {
        deduplicated.add(entry);
      }
    }
    deduplicated.sort((a, b) => b.time.compareTo(a.time));
    return deduplicated.take(count).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return StreamBuilder<HistoryState>(
      stream: _historyRepo.getHistoryState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        final historyState = snapshot.data!;
        // The HistoryRepository accumulates every LogsEvent it observes on the
        // app-wide event bus (see HistoryRepository.scan), and that bus is
        // shared with other consumers such as the Activity tab. Depending on
        // navigation timing, more (or fewer) entries than requested can end up
        // in the state, which made Recent Activity show an inconsistent count
        // (e.g. 4 on a fresh launch but 2 after navigating away and back).
        // Always derive a deterministic, bounded view here so the widget shows
        // the same number of items regardless of what lands on the bus. See #126.
        final logEntries = _mostRecentEntries(
          historyState.logEntries,
          widget.amountOfLogs,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: TranslatedText(
                      "home_tab.recent_activity",
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ),
                Flexible(
                  child: YiviThemedButton(
                    label: "home_tab.view_more",
                    size: YiviButtonSize.small,
                    style: YiviButtonStyle.outlined,
                    isTransparent: true,
                    onPressed: widget.onTap,
                  ),
                ),
              ],
            ),
            SizedBox(height: theme.defaultSpacing),
            logEntries.isEmpty
                ? const TranslatedText("activity.empty_placeholder")
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: logEntries
                        .map(
                          (logEntry) => Padding(
                            padding: EdgeInsets.only(
                              bottom: theme.smallSpacing,
                            ),
                            child: ActivityCard(logEntry: logEntry),
                          ),
                        )
                        .toList(),
                  ),
          ],
        );
      },
    );
  }
}
