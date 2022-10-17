import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../models/session_events.dart';
import '../../../theme/theme.dart';
import '../../../util/combine.dart';
import '../../../widgets/irma_repository_provider.dart';
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

  List<Widget> _decorateForHomeTab(BuildContext context, Widget child) {
    final theme = IrmaTheme.of(context);
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TranslatedText(
            'home_tab.recent_activity',
            style: theme.textTheme.headline4,
          ),
          GestureDetector(
            key: const Key('home_recent_activity_link'),
            onTap: widget.onTap,
            child: TranslatedText('home_tab.view_more', style: theme.hyperlinkTextStyle),
          )
        ],
      ),
      SizedBox(height: theme.defaultSpacing),
      child,
      SizedBox(height: theme.largeSpacing),
    ];
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<CombinedState2<IrmaConfiguration, HistoryState>>(
      stream: combine2(_historyRepo.repo.getIrmaConfiguration(), _historyRepo.getHistoryState()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        final irmaConfiguration = snapshot.data!.a;
        final historyState = snapshot.data!.b;
        final logEntries = historyState.logEntries;

        if (logEntries.isEmpty) {
          return Container();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _decorateForHomeTab(
            context,
            Column(
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
          ),
        );
      });
}