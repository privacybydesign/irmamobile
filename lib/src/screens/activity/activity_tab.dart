import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';

import '../../models/irma_configuration.dart';
import '../../models/log_entry.dart';
import '../../models/session_events.dart';
import '../../theme/theme.dart';
import '../../util/combine.dart';
import '../../util/navigation.dart';
import '../../util/string.dart';
import '../../widgets/end_of_list_indicator.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/translated_text.dart';
import '../notifications/bloc/notifications_bloc.dart';
import '../notifications/widgets/notification_bell.dart';
import 'history_repository.dart';
import 'widgets/activity_card.dart';

class ActivityTab extends StatefulWidget {
  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  late final HistoryRepository _historyRepo;
  final _scrollController = ScrollController();
  late StreamSubscription _repoStateSubscription;

  @override
  void initState() {
    super.initState();
    //Delay to make build context available
    Future.delayed(Duration.zero).then((_) async {
      _loadInitialLogs();
      if (!mounted) {
        return;
      }
      _repoStateSubscription = IrmaRepositoryProvider.of(context).getEvents().listen((event) {
        if (event is SuccessSessionEvent) {
          _loadInitialLogs();
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // only init _historyRepo once...
    try {
      _historyRepo;
    } catch (_) {
      _historyRepo = HistoryRepository(IrmaRepositoryProvider.of(context));
    }
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
              child: Semantics(
                header: true,
                child: Text(
                  DateFormat('MMMM', local).format(logEntry.time).toCapitalized(),
                  style: theme.themeData.textTheme.displaySmall,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(bottom: theme.smallSpacing),
            child: ActivityCard(
              logEntry: logEntry,
              irmaConfiguration: irmaConfiguration,
            ),
          ),
        ];
      },
    ).flattened.toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        vertical: theme.smallSpacing,
        horizontal: theme.defaultSpacing,
      ),
      children: [
        if (groupedItems.isEmpty)
          const Center(
            child: TranslatedText('activity.empty_placeholder'),
          )
        else ...[
          ...groupedItems,
          Padding(
            padding: EdgeInsets.only(
              top: theme.defaultSpacing,
              bottom: theme.mediumSpacing,
            ),
            child: EndOfListIndicator(
              isLoading: moreLogsAvailable,
            ),
          ),
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(_listenToScroll);
    return Scaffold(
      backgroundColor: IrmaTheme.of(context).backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'home.nav_bar.activity',
        leading: null,
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) => NotificationBell(
              showIndicator: state is NotificationsLoaded ? state.hasUnreadNotifications : false,
              onTap: context.goNotificationsScreen,
            ),
          )
        ],
      ),
      body: StreamBuilder<CombinedState2<IrmaConfiguration, HistoryState>>(
        stream: combine2(_historyRepo.repo.getIrmaConfiguration(), _historyRepo.getHistoryState()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: LoadingIndicator());
          }
          final irmaConfiguration = snapshot.data!.a;
          final historyState = snapshot.data!.b;
          return _buildLogEntries(context, irmaConfiguration, historyState.logEntries, historyState.moreLogsAvailable);
        },
      ),
    );
  }
}
