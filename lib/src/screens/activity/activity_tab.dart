import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';

import '../../models/irma_configuration.dart';
import '../../models/log_entry.dart';
import '../../models/session_events.dart';
import '../../theme/irma_icons.dart';
import '../../theme/theme.dart';
import '../../util/capitalize.dart';
import '../../util/combine.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/loading_indicator.dart';
import 'history_repository.dart';
import 'widgets/activity_card.dart';

class ActivityTab extends StatefulWidget {
  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  final HistoryRepository _historyRepo = HistoryRepository();
  final _scrollController = ScrollController();
  late StreamSubscription _repoStateSubscription;

  @override
  void initState() {
    super.initState();
    //Delay to make build context available
    Future.delayed(Duration.zero).then((_) async {
      _loadInitialLogs();
      _repoStateSubscription = IrmaRepositoryProvider.of(context).getEvents().listen((event) {
        if (event is SuccessSessionEvent) {
          _loadInitialLogs();
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

  void _loadInitialLogs() {
    IrmaRepositoryProvider.of(context).bridgedDispatch(LoadLogsEvent(max: 10));
  }

  Future<void> _loadMoreLogs() async {
    final historyState = await _historyRepo.getHistoryState().first;
    if (historyState.moreLogsAvailable && !historyState.loading && mounted) {
      IrmaRepositoryProvider.of(context)
          .bridgedDispatch(LoadLogsEvent(before: historyState.logEntries.last.id, max: 10));
    }
  }

  void _addPostFrameCallback() {
    // After list is initially rendered, there might not be enough logs to trigger the scroll controller.
    // In that case, load more logs to fully fill the screen.
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      if (_scrollController.position.maxScrollExtent - _scrollController.position.minScrollExtent < 80) {
        _loadMoreLogs();
      }
    });
  }

  void _listenToScroll() {
    // When scrollbar is at the end, load more logs
    if (_scrollController.position.maxScrollExtent - _scrollController.position.pixels < 80) {
      _loadMoreLogs();
    }
  }

  Widget _buildLogEntries(BuildContext context, IrmaConfiguration irmaConfiguration, HistoryState historyState) {
    _addPostFrameCallback();
    final local = FlutterI18n.currentLocale(context).toString();
    final theme = IrmaTheme.of(context);
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          vertical: theme.smallSpacing,
          horizontal: theme.defaultSpacing,
        ),
        itemCount: historyState.logEntries.length,
        itemBuilder: (context, index) {
          final logEntry = historyState.logEntries[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //If the months differ, or its the first item, add month header
              if (index == 0 || (index > 0 && historyState.logEntries[index - 1].time.month != logEntry.time.month))
                Padding(
                  padding: EdgeInsets.only(
                    top: index > 0 ? theme.defaultSpacing : 0, // If is not first add padding to top.
                    left: theme.tinySpacing,
                    right: theme.tinySpacing,
                    bottom: theme.tinySpacing,
                  ),
                  child: Text(DateFormat('MMMM', local).format(logEntry.time).toCapitalized(),
                      style: theme.themeData.textTheme.headline3),
                ),
              ActivityCard(
                logEntry: logEntry,
                irmaConfiguration: irmaConfiguration,
              ),
              // Put loading indicator or loading finished icon at end of ListView
              if (index == historyState.logEntries.length - 1)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
                  child: Center(
                    child: historyState.moreLogsAvailable
                        ? SizedBox(
                            height: 36,
                            child: LoadingIndicator(),
                          )
                        : Icon(IrmaIcons.valid, color: theme.success),
                  ),
                )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(_listenToScroll);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const IrmaAppBar(
        titleTranslationKey: 'home.nav_bar.activity',
        noLeading: true,
      ),
      StreamBuilder<CombinedState2<IrmaConfiguration, HistoryState>>(
        stream: combine2(_historyRepo.repo.getIrmaConfiguration(), _historyRepo.getHistoryState()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          final irmaConfiguration = snapshot.data!.a;
          final historyState = snapshot.data!.b;
          return _buildLogEntries(context, irmaConfiguration, historyState);
        },
      )
    ]);
  }
}
