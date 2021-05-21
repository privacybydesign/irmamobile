import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:irmamobile/src/screens/history/detail_screen.dart';
import 'package:irmamobile/src/screens/history/history_repository.dart';
import 'package:irmamobile/src/screens/history/widgets/log_entry_card.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/combine.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';

class HistoryScreen extends StatefulWidget {
  static const routeName = "/history";

  @override
  HistoryScreenState createState() {
    return HistoryScreenState();
  }
}

class HistoryScreenState extends State<HistoryScreen> {
  final HistoryRepository _historyRepo = HistoryRepository();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialLogs();
  }

  @override
  void dispose() {
    _historyRepo.dispose();
    super.dispose();
  }

  void _loadInitialLogs() {
    IrmaRepository.get().bridgedDispatch(LoadLogsEvent(max: 10));
  }

  Future<void> _loadMoreLogs() async {
    final historyState = await _historyRepo.getHistoryState().first;
    if (historyState.moreLogsAvailable && !historyState.loading) {
      IrmaRepository.get().bridgedDispatch(LoadLogsEvent(before: historyState.logEntries.last.id, max: 10));
    }
  }

  Widget _buildLogEntries(BuildContext context, IrmaConfiguration irmaConfiguration, HistoryState historyState) {
    _addPostFrameCallback();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      itemCount: historyState.logEntries.length + 2,
      itemBuilder: (context, index) {
        // Add some padding at begin of ListView
        if (index == 0) {
          return SizedBox(height: IrmaTheme.of(context).smallSpacing);
        }

        // Put loading indicator or loading finished icon at end of ListView
        if (index == historyState.logEntries.length + 1) {
          if (!historyState.moreLogsAvailable) {
            // Icon to indicate end of list
            return Center(
              heightFactor: 2,
              child: Icon(IrmaIcons.valid, color: IrmaTheme.of(context).interactionValid),
            );
          }

          return Center(child: LoadingIndicator());
        }

        final logEntry = historyState.logEntries[index - 1];
        return LogEntryCard(
          key: Key('logentry_$index'),
          irmaConfiguration: irmaConfiguration,
          logEntry: logEntry,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(logEntry: logEntry, irmaConfiguration: irmaConfiguration),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(_listenToScroll);

    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(
          FlutterI18n.translate(context, 'history.title'),
        ),
      ),
      body: StreamBuilder<CombinedState2<IrmaConfiguration, HistoryState>>(
        stream: combine2(_historyRepo.repo.getIrmaConfiguration(), _historyRepo.getHistoryState()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }

          final irmaConfiguration = snapshot.data.a;
          final historyState = snapshot.data.b;
          return _buildLogEntries(context, irmaConfiguration, historyState);
        },
      ),
    );
  }

  void _listenToScroll() {
    // When scrollbar is at the end, load more logs
    if (_scrollController.position.maxScrollExtent - _scrollController.position.pixels < 80) {
      _loadMoreLogs();
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
}
