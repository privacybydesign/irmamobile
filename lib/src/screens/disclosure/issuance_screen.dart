import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/disclosure/session_screen.dart';
import 'package:irmamobile/src/screens/history/widgets/issuing_detail.dart';

class IssuanceScreen extends StatefulWidget {
  static const String routeName = "/issuance";

  final SessionScreenArguments arguments;

  const IssuanceScreen({this.arguments}) : super();

  @override
  _IssuanceScreenState createState() => _IssuanceScreenState();
}

class _IssuanceScreenState extends SessionWidgetState<IssuanceScreen> {
  @override
  String get title => 'issuance.title';

  @override
  Widget buildContents(SessionState session) => IssuingDetail(session.issuedCredentials);

  @override
  Widget buildHeader(SessionState session) {
    return Text(
      FlutterI18n.plural(context, 'issuance.header', session.issuedCredentials.length),
      style: Theme.of(context).textTheme.body1,
    );
  }

  @override
  void declinePermission(BuildContext context, String otherParty) {
    dispatchSessionEvent(RespondPermissionEvent(
      proceed: false,
      disclosureChoices: [],
    ));
    popToWallet(context);
  }

  @override
  void finishOnSecondDevice(BuildContext context, String otherParty) => popToWallet(context);

  @override
  void initState() {
    super.initState();
    sessionID = widget.arguments.sessionID;
    sessionStateStream = repo.getSessionState(widget.arguments.sessionID);
    handleSuccess();
  }
}
