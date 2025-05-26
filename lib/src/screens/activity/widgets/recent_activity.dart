import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../models/session_events.dart';
import '../../../providers/irma_repository_provider.dart';
import '../../../theme/theme.dart';
import '../../../util/combine.dart';
import '../../../widgets/translated_text.dart';
import '../../../widgets/yivi_themed_button.dart';
import '../history_repository.dart';
import 'activity_card.dart';

class RecentActivity extends StatefulWidget {
  final int amountOfLogs;
  final VoidCallback onTap;

  const RecentActivity({
    required this.onTap,
    this.amountOfLogs = 2,
  });

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
      _repoStateSubscription = IrmaRepositoryProvider.of(context).getEvents().listen((event) {
        if (event is SuccessSessionEvent) {
          _loadLogs();
        }
      });
    }
  }

  @override
  void dispose() {
    _historyRepo.dispose();
    _repoStateSubscription.cancel();
    super.dispose();
  }

  void _loadLogs() {
    IrmaRepositoryProvider.of(context).bridgedDispatch(LoadLogsEvent(
      max: widget.amountOfLogs,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return StreamBuilder<CombinedState2<IrmaConfiguration, HistoryState>>(
      stream: combine2(_historyRepo.repo.getIrmaConfiguration(), _historyRepo.getHistoryState()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        final irmaConfiguration = snapshot.data!.a;
        final historyState = snapshot.data!.b;
        final logEntries = historyState.logEntries;

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
                      'home_tab.recent_activity',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ),
                Flexible(
                  child: YiviThemedButton(
                    label: 'home_tab.view_more',
                    size: YiviButtonSize.small,
                    style: YiviButtonStyle.outlined,
                    isTransparent: true,
                    onPressed: widget.onTap,
                  ),
                )
              ],
            ),
            SizedBox(height: theme.defaultSpacing),
            logEntries.isEmpty
                ? const TranslatedText('activity.empty_placeholder')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: logEntries
                        .map(
                          (logEntry) => Padding(
                            padding: EdgeInsets.only(bottom: theme.smallSpacing),
                            child: ActivityCard(
                              logEntry: logEntry,
                              irmaConfiguration: irmaConfiguration,
                            ),
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
