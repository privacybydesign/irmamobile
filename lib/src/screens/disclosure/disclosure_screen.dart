import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/disclosure/widgets/arrow_back_screen.dart';
import 'package:irmamobile/src/screens/disclosure/widgets/disclosure_feedback_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_quote.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'carousel.dart';

class DisclosureScreenArguments {
  final int sessionID;

  DisclosureScreenArguments({this.sessionID});
}

class DisclosureScreen extends StatefulWidget {
  static const String routeName = "/disclosure";

  final DisclosureScreenArguments arguments;

  const DisclosureScreen({this.arguments}) : super();

  @override
  _DisclosureScreenState createState() => _DisclosureScreenState();
}

class _DisclosureScreenState extends State<DisclosureScreen> {
  final String _lang = "nl"; // TODO: this shouldn't be hardcoded.
  final IrmaRepository _repo = IrmaRepository.get();
  Stream<SessionState> _sessionStateStream;

  bool _displayArrowBack = false;

  @override
  void initState() {
    super.initState();

    _sessionStateStream = _repo.getSessionState(widget.arguments.sessionID);

    _sessionStateStream
        .firstWhere((session) => session.disclosuresCandidates != null)
        .then((session) => _showExplanation(session.disclosuresCandidates));

    // Session success handling
    (() async {
      // When the session has completed, wait one second to display a message
      final session = await _sessionStateStream.firstWhere((session) => session.status == SessionStatus.success);
      await Future.delayed(const Duration(seconds: 1));

      if (session.continueOnSecondDevice && !session.isReturnPhoneNumber) {
        // If this is a session on a second screen, return to the wallet after showing a feedback screen,
        // unless a return URL with a phone number was provided
        _pushDisclosureFeedbackScreen(true, session.serverName.translate(_lang));
      } else if (session.clientReturnURL != null && await canLaunch(session.clientReturnURL)) {
        // If there is a return URL, navigate to it when we're done
        launch(session.clientReturnURL, forceSafariVC: false);
        _popToWallet(context);
      } else {
        // Otherwise, on iOS show a screen to press the return arrow in the top-left corner,
        // and on Android just background the app to let the user return to the previous activity
        if (Platform.isIOS) {
          setState(() => _displayArrowBack = true);
        } else {
          SystemNavigator.pop();
          _popToWallet(context);
        }
      }
    })();
  }

  void _popToWallet(BuildContext context) {
    Navigator.of(context).popUntil(
      ModalRoute.withName(
        WalletScreen.routeName,
      ),
    );
  }

  void _pushDisclosureFeedbackScreen(bool success, String otherParty) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DisclosureFeedbackScreen(
        success: success,
        otherParty: otherParty,
        popToWallet: _popToWallet,
      ),
    ));
  }

  void _dispatchSessionEvent(SessionEvent event) {
    event.sessionID = widget.arguments.sessionID;
    _repo.bridgedDispatch(event);
  }

  void _dismissSession() {
    _dispatchSessionEvent(DismissSessionEvent());
  }

  void _declinePermission(BuildContext context, String otherParty) {
    _dispatchSessionEvent(RespondPermissionEvent(
      proceed: false,
      disclosureChoices: [],
    ));

    _pushDisclosureFeedbackScreen(false, otherParty);
  }

  void _givePermission(SessionState session) {
    _dispatchSessionEvent(RespondPermissionEvent(
      proceed: true,
      disclosureChoices: session.disclosuresCandidates.map((discon) {
        return discon.first
            .map((credentialAttribute) => AttributeIdentifier.fromCredentialAttribute(credentialAttribute))
            .toList();
      }).toList(),
    ));
  }

  Widget _buildDisclosureHeader(SessionState session) {
    final serverName = session.serverName.translate(_lang);

    if (session.isReturnPhoneNumber) {
      return TranslatedText(
        'disclosure.disclosure_call_header',
        translationParams: {
          'serverName': serverName,
          'phoneNumber': session.clientReturnURL.substring(4).split(",").first,
        },
      );
    }

    return TranslatedText(
      'disclosure.disclosure_header',
      translationParams: {
        'serverName': serverName,
      },
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

  Widget _buildNavigationBar() {
    return StreamBuilder<SessionState>(
      stream: _sessionStateStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(height: 0);
        }

        final session = snapshot.data;
        if (session.status != SessionStatus.requestPermission) {
          return Container(height: 0);
        }

        return IrmaBottomBar(
          primaryButtonLabel: FlutterI18n.translate(context, "disclosure.navigation_bar.yes"),
          primaryButtonIcon: session.isReturnPhoneNumber ? Icons.phone : null,
          onPrimaryPressed: () => _givePermission(session),
          secondaryButtonLabel: FlutterI18n.translate(context, "disclosure.navigation_bar.no"),
          onSecondaryPressed: () => _declinePermission(context, session.serverName.translate(_lang)),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(children: [
      Center(
        child: LoadingIndicator(),
      ),
    ]);
  }

  Widget _buildDisclosureChoices(SessionState session) {
    // TODO: See how disclosure_card.dart fits in here
    return ListView(
      padding: EdgeInsets.all(IrmaTheme.of(context).smallSpacing),
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: IrmaTheme.of(context).mediumSpacing,
            horizontal: IrmaTheme.of(context).smallSpacing,
          ),
          child: session.isSignatureSession ? _buildSigningHeader(session) : _buildDisclosureHeader(session),
        ),
        Card(
          elevation: 1.0,
          semanticContainer: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IrmaTheme.of(context).defaultSpacing),
            side: const BorderSide(color: Color(0xFFDFE3E9), width: 1),
          ),
          color: IrmaTheme.of(context).primaryLight,
          child: Column(
            children: [
              SizedBox(height: IrmaTheme.of(context).smallSpacing),
              ...session.disclosuresCandidates
                  .asMap()
                  .entries
                  .expand(
                    (entry) => [
                      // Display a divider except for the first element
                      if (entry.key != 0)
                        Divider(
                          color: IrmaTheme.of(context).grayscale80,
                        ),
                      Carousel(candidatesDisCon: entry.value)
                    ],
                  )
                  .toList(),
              SizedBox(height: IrmaTheme.of(context).smallSpacing),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_displayArrowBack) {
      return ArrowBack();
    }

    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(FlutterI18n.translate(context, 'disclosure.title')),
      ),
      backgroundColor: IrmaTheme.of(context).grayscaleWhite,
      bottomNavigationBar: _buildNavigationBar(),
      body: StreamBuilder(
        stream: _sessionStateStream,
        builder: (BuildContext context, AsyncSnapshot<SessionState> sessionStateSnapshot) {
          if (!sessionStateSnapshot.hasData) {
            return _buildLoadingIndicator();
          }

          final session = sessionStateSnapshot.data;
          if (session.status == SessionStatus.requestPermission) {
            return _buildDisclosureChoices(session);
          }

          return _buildLoadingIndicator();
        },
      ),
    );
  }

  Future<void> _showExplanation(ConDisCon<CredentialAttribute> candidatesConDisCon) async {
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
