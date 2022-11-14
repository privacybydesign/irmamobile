import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../models/session_events.dart';
import '../../../theme/theme.dart';
import '../../../util/combine.dart';
import '../../../widgets/irma_button.dart';
import '../../../widgets/irma_repository_provider.dart';
import '../../../widgets/irma_themed_button.dart';
import '../../../widgets/translated_text.dart';
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
  final HistoryRepository _historyRepo = HistoryRepository();
  late StreamSubscription _repoStateSubscription;

  @override
  void initState() {
    super.initState();
    //Delay to make build context available
    Future.delayed(Duration.zero).then((_) async {
      _loadLogs();
      _repoStateSubscription = IrmaRepositoryProvider.of(context).getEvents().listen((event) {
        if (event is SuccessSessionEvent) {
          _loadLogs();
        }
      });
    });
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
                  child: TranslatedText(
                    'home_tab.recent_activity',
                    style: theme.textTheme.headline4,
                  ),
                ),
                Flexible(
                  child: IrmaButton(
                    label: 'home_tab.view_more',
                    textStyle: theme.textTheme.bodyText1!.copyWith(
                      color: theme.themeData.colorScheme.secondary,
                      fontSize: 12,
                    ),
                    onPressed: widget.onTap,
                    size: IrmaButtonSize.extraSmall,
                    isSecondary: true,
                    minWidth: 130,
                  ),
                ),
              ],
            ),
            SizedBox(height: theme.defaultSpacing),
            logEntries.isEmpty
                ? const TranslatedText('activity.empty_placeholder')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: logEntries
                        .map(
                          (logEntry) => ActivityCard(
                            logEntry: logEntry,
                            irmaConfiguration: irmaConfiguration,
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
