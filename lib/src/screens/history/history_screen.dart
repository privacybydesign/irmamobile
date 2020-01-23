import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/log.dart' as log_model;
import 'package:irmamobile/src/screens/history/detail_screen.dart';
import 'package:irmamobile/src/screens/history/model/history_bloc.dart';
import 'package:irmamobile/src/screens/history/model/history_events.dart';
import 'package:irmamobile/src/screens/history/widgets/log.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';

import 'model/history_state.dart';

class HistoryScreen extends StatefulWidget {
  static const routeName = "/history";

  @override
  HistoryScreenState createState() {
    return HistoryScreenState();
  }
}

class HistoryScreenState extends State<HistoryScreen> {
  final _scrollController = ScrollController();
  final _bloc = HistoryBloc(IrmaRepository.get());
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(_listenToScroll);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          FlutterI18n.translate(context, 'history.title'),
        ),
      ),
      body: BlocBuilder(
        bloc: _bloc,
        builder: (context, HistoryState state) {
          return RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _handleRefresh,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              itemCount: state.loading ? state.logs.length + 1 : state.logs.length,
              itemBuilder: (context, index) {
                if (state.loading && index == state.logs.length) {
                  return Center(
                    child: LoadingIndicator(),
                  );
                }
                return _buildLog(state.logs[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleRefresh() {
    _bloc.dispatch(Refresh());
    return Future.value();
  }

  Log _buildLog(log_model.Log logModel) {
    LogType logType;
    int dataCount = 1;
    String subTitle;
    switch (logModel.type) {
      case "issuing":
        logType = LogType.issuing;
        dataCount = logModel.issuedCredentials.length;
        subTitle = getTranslation(logModel.issuedCredentials.entries.first.value.issuer.name);
        break;
      case "disclosing":
        logType = LogType.disclosing;
        dataCount = logModel.disclosedAttributes.length;
        subTitle = "gemeente x";
        break;
      case "signing":
        logType = LogType.signing;
        subTitle = "gemeente x";
        break;
      case "removal":
        logType = LogType.removal;
        subTitle = logModel.removedCredentials.entries.first.value;
    }
    return Log(
      type: logType,
      dataCount: dataCount,
      subTitle: subTitle,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailScreen(logModel, logType)));
      },
    );
  }

  void _listenToScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        _bloc.startingState.moreLogsAvailable) {
      _bloc.dispatch(LoadMore());
    }
  }
}
