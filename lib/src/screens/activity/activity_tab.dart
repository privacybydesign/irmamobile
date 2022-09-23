import 'dart:async';

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
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

  Widget _buildLogEntries(
      BuildContext context, IrmaConfiguration irmaConfiguration, List<LogEntry> logEntries, bool moreLogsAvailable) {
    _addPostFrameCallback();
    final local = FlutterI18n.currentLocale(context).toString();
    final theme = IrmaTheme.of(context);

    final groupedItems = List.generate(
      logEntries.length,
      (index) {
        final logEntry = logEntries[index];
        final insertMonthSeparator = index == 0 || index > 0 && logEntries[index - 1].time.month != logEntry.time.month;
        return [
          if (insertMonthSeparator)
            Padding(
              padding: EdgeInsets.only(
                // If is not first add padding to top.
                top: index > 0 ? theme.defaultSpacing : 0,
                left: theme.tinySpacing,
                right: theme.tinySpacing,
                bottom: theme.tinySpacing,
              ),
              child: Text(
                DateFormat('MMMM', local).format(logEntry.time).toCapitalized(),
                style: theme.themeData.textTheme.headline3,
              ),
            ),
          ActivityCard(
            logEntry: logEntry,
            irmaConfiguration: irmaConfiguration,
          ),
        ];
      },
    ).flattened.toList()
      ..add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
          child: Center(
            child: moreLogsAvailable
                ? SizedBox(
                    height: 36,
                    child: LoadingIndicator(),
                  )
                : Icon(IrmaIcons.valid, color: theme.success),
          ),
        ),
      );

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        vertical: theme.smallSpacing,
        horizontal: theme.defaultSpacing,
      ),
      children: groupedItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(_listenToScroll);
    return Scaffold(
      appBar: const IrmaAppBar(
        titleTranslationKey: 'home.nav_bar.activity',
        noLeading: true,
      ),
      body: StreamBuilder<CombinedState2<IrmaConfiguration, HistoryState>>(
        stream: combine2(_historyRepo.repo.getIrmaConfiguration(), _historyRepo.getHistoryState()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: LoadingIndicator());
          }
          final irmaConfiguration = snapshot.data!.a;
          final historyState = snapshot.data!.b;
          // hack to remove the first activity logged by the bridge
          final logEntries = historyState.moreLogsAvailable
              ? historyState.logEntries.sublist(0, historyState.logEntries.length - 1)
              : historyState.logEntries;
          return _buildLogEntries(context, irmaConfiguration, logEntries, historyState.moreLogsAvailable);
        },
      ),
    );
  }
}
