import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/disclosure/session_screen.dart';
import 'package:irmamobile/src/screens/disclosure/widgets/disclosure_feedback_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/disclosure/disclosure_card.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_quote.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class DisclosureScreen extends StatefulWidget {
  static const String routeName = "/disclosure";

  final SessionScreenArguments arguments;

  const DisclosureScreen({this.arguments}) : super();

  @override
  _DisclosureScreenState createState() => _DisclosureScreenState();
}

class _DisclosureScreenState extends SessionWidgetState<DisclosureScreen> {
  final String _lang = "nl"; // TODO: this shouldn't be hardcoded.

  @override
  String get title => 'disclosure.title';

  @override
  Widget buildContents(SessionState session) => DisclosureCard(
        candidatesConDisCon: session.disclosuresCandidates,
        onCurrentPageUpdate: _carouselPageUpdate,
      );

  @override
  Widget buildHeader(SessionState session) {
    if (session.isSignatureSession) {
      return _buildSigningHeader(session);
    } else {
      return _buildDisclosureHeader(session);
    }
  }

  @override
  void declinePermission(BuildContext context, String otherParty) {
    dispatchSessionEvent(RespondPermissionEvent(
      proceed: false,
      disclosureChoices: [],
    ));

    _pushDisclosureFeedbackScreen(false, otherParty);
  }

  @override
  void finishOnSecondDevice(BuildContext context, String otherParty) => _pushDisclosureFeedbackScreen(true, otherParty);

  @override
  void initState() {
    super.initState();
    sessionID = widget.arguments.sessionID;
    sessionStateStream = repo.getSessionState(widget.arguments.sessionID);
    sessionStateStream
        .firstWhere((session) => session.disclosuresCandidates != null)
        .then((session) => _showExplanation(session.disclosuresCandidates));
    handleSuccess();
  }

  void _pushDisclosureFeedbackScreen(bool success, String otherParty) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DisclosureFeedbackScreen(
        success: success,
        otherParty: otherParty,
        popToWallet: popToWallet,
      ),
    ));
  }

  void _carouselPageUpdate(int disconIndex, int conIndex) {
    dispatchSessionEvent(
      DisclosureChoiceUpdateSessionEvent(
        disconIndex: disconIndex,
        conIndex: conIndex,
      ),
      isBridgedEvent: false,
    );
  }

  Widget _buildDisclosureHeader(SessionState session) {
    return TranslatedText(
      'disclosure.disclosure_header',
      translationParams: {"otherParty": session.serverName.translate(_lang)},
      style: Theme.of(context).textTheme.body1,
    );
  }

  Widget _buildSigningHeader(SessionState session) {
    return Column(children: [
      Text.rich(
        TextSpan(children: [
          TextSpan(
            text: session.serverName.translate(_lang),
            style: IrmaTheme.of(context).textTheme.body2,
          ),
          TextSpan(
            text: FlutterI18n.translate(context, 'disclosure.signing_header'),
            style: IrmaTheme.of(context).textTheme.body1,
          ),
        ]),
      ),
      Padding(
        padding: EdgeInsets.only(top: IrmaTheme.of(context).mediumSpacing),
        child: IrmaQuote(quote: session.signedMessage),
      ),
    ]);
  }

  Future<void> _showExplanation(ConDisCon<Attribute> candidatesConDisCon) async {
    final irmaPrefs = IrmaPreferences.get();

    final bool showDisclosureDialog = await irmaPrefs.getShowDisclosureDialog().first;
    final hasChoice = candidatesConDisCon.any((candidatesDisCon) => candidatesDisCon.length > 1);

    if (!showDisclosureDialog || !hasChoice) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => IrmaDialog(
        title: FlutterI18n.translate(context, 'disclosure.explanation.title'),
        content: FlutterI18n.translate(context, 'disclosure.explanation.body'),
        image: 'assets/disclosure/disclosure-explanation.webp',
        child: Wrap(
          direction: Axis.horizontal,
          verticalDirection: VerticalDirection.up,
          alignment: WrapAlignment.spaceEvenly,
          children: <Widget>[
            IrmaTextButton(
              onPressed: () async {
                await irmaPrefs.setShowDisclosureDialog(false);
                Navigator.of(context).pop();
              },
              minWidth: 0.0,
              label: 'disclosure.explanation.dismiss-remember',
            ),
            IrmaButton(
              size: IrmaButtonSize.small,
              minWidth: 0.0,
              onPressed: () {
                Navigator.of(context).pop();
              },
              label: 'disclosure.explanation.dismiss',
            ),
          ],
        ),
      ),
    );
  }
}
