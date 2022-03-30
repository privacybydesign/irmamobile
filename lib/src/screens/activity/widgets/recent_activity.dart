import 'dart:async';

import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/screens/activity/history_repository.dart';
import 'package:irmamobile/src/screens/activity/widgets/activity_card.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/combine.dart';
import 'package:irmamobile/src/widgets/irma_repository_provider.dart';

class RecentActivity extends StatefulWidget {
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
    IrmaRepositoryProvider.of(context).bridgedDispatch(LoadLogsEvent(max: 5));
  }

  List<Widget> _buildLogEntries(BuildContext context, IrmaConfiguration irmaConfiguration, HistoryState historyState) {
    final List<Widget> widgets = [];
    for (final logEntry in historyState.logEntries) {
      widgets.add(Padding(
        padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).tinySpacing),
        child: ActivityCard(logEntry: logEntry, irmaConfiguration: irmaConfiguration),
      ));
    }
    return widgets;
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
          children: _buildLogEntries(context, irmaConfiguration, historyState),
        );
      },
    );
  }
}
