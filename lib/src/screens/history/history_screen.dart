import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:irmamobile/src/screens/history/detail_screen.dart';
import 'package:irmamobile/src/screens/history/widgets/log.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
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
  final _scrollController = ScrollController();
  // final _bloc = HistoryBloc(IrmaRepository.get());
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  IrmaConfiguration irmaConfiguration;

  @override
  void initState() {
    super.initState();

    IrmaRepository.get().bridgedDispatch(LoadLogsEvent(max: 10));
    IrmaRepository.get().getIrmaConfiguration().listen((irmaConfiguration) {
      this.irmaConfiguration = irmaConfiguration;
    });
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
      body: StreamBuilder<List<LogEntry>>(
        stream: IrmaRepository.get().getLogs(),
        builder: (context, snapshot) {
          return RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _handleRefresh,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              itemCount: snapshot.hasData ? snapshot.data.length : 1,
              itemBuilder: (context, index) {
                if (!snapshot.hasData && index == 0) {
                  return Center(
                    child: LoadingIndicator(),
                  );
                }
                return _buildLog(snapshot.data[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleRefresh() {
    // _bloc.dispatch(Refresh());
    return Future.value();
  }

  Log _buildLog(LogEntry logEntry) {
    LogType logType;
    int dataCount = 1;
    String subTitle;
    switch (logEntry.type) {
      case "issuing":
        logType = LogType.issuing;
        dataCount = logEntry.issuedCredentials.length;
        subTitle = getTranslation(irmaConfiguration.issuers[logEntry.issuedCredentials.first.fullIssuerId].name);
        break;
      case "disclosing":
        logType = LogType.disclosing;
        dataCount = logEntry.disclosedAttributes.length;
        // subTitle = "gemeente x";
        break;
      case "signing":
        logType = LogType.signing;
        // subTitle = "gemeente x";
        break;
      case "removal":
        logType = LogType.removal;
        subTitle = getTranslation(logEntry.removedCredentials.values.first);
    }
    return Log(
      type: logType,
      dataCount: dataCount,
      subTitle: subTitle,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailScreen(logEntry: logEntry)));
      },
    );
  }

  void _listenToScroll() {
    // if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
    //     _bloc.startingState.moreLogsAvailable) {
    //   _bloc.dispatch(LoadMore());
    // }
  }
}
