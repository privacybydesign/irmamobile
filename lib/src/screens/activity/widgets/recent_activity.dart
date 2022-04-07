import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../models/session_events.dart';
import '../../../util/combine.dart';
import '../../../widgets/irma_repository_provider.dart';
import '../history_repository.dart';
import 'activity_card.dart';

class RecentActivity extends StatefulWidget {
  final int amountOfLogs;

  const RecentActivity({this.amountOfLogs = 5});

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
    return StreamBuilder<CombinedState2<IrmaConfiguration, HistoryState>>(
      stream: combine2(_historyRepo.repo.getIrmaConfiguration(), _historyRepo.getHistoryState()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        final irmaConfiguration = snapshot.data!.a;
        final historyState = snapshot.data!.b;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: historyState.logEntries
              .map(
                (logEntry) => ActivityCard(
                  logEntry: logEntry,
                  irmaConfiguration: irmaConfiguration,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
