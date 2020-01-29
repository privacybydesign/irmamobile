import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:irmamobile/src/models/verifier.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

import 'carousel.dart';

class DisclosureScreenArguments {
  final int sessionID;

  DisclosureScreenArguments({this.sessionID});
}

class SessionState {
  String status;
  TranslatedValue serverName;
  ConDisCon<CredentialAttribute> candidatesConDisCon;

  SessionState({this.status, this.serverName, this.candidatesConDisCon});

  SessionState copyWith(
      {String status, TranslatedValue serverName, ConDisCon<CredentialAttribute> candidatesConDisCon}) {
    return SessionState(
      status: status ?? this.status,
      serverName: serverName ?? this.serverName,
      candidatesConDisCon: candidatesConDisCon ?? this.candidatesConDisCon,
    );
  }
}

class DisclosureScreen extends StatelessWidget {
  static const String routeName = '/disclosure';

  // final _sessionStateSubject = BehaviorSubject<SessionState>.seeded(SessionState());

  @override
  Widget build(BuildContext context) {
    final screenArguments = ModalRoute.of(context).settings.arguments as DisclosureScreenArguments;
    final repo = IrmaRepository.get();

    SessionState prevSessionState = SessionState();
    final sessionStateStream = repo.getSessionEvents(screenArguments.sessionID).asyncMap((event) async {
      final irmaConfiguration = await repo.getIrmaConfiguration().first;
      final credentials = await repo.getCredentials().first;

      if (event is StatusUpdateSessionEvent) {
        return prevSessionState = prevSessionState.copyWith(
          status: event.status,
        );
      } else if (event is RequestVerificationPermissionSessionEvent) {
        return prevSessionState = prevSessionState.copyWith(
          serverName: event.serverName,
          candidatesConDisCon: ConDisCon.fromRaw<AttributeIdentifier, CredentialAttribute>(event.disclosuresCandidates,
              (attributeIdentifier) {
            return CredentialAttribute.fromAttributeIdentifier(irmaConfiguration, credentials, attributeIdentifier);
          }),
        );
      } else {
        return prevSessionState;
      }
    });

    return ProvidedDisclosureScreen(sessionStateStream: sessionStateStream);
  }
}

class ProvidedDisclosureScreen extends StatefulWidget {
  final Stream<SessionState> sessionStateStream;
  final List<List<VerifierCredential>> issuers = [];

  ProvidedDisclosureScreen({this.sessionStateStream}) : super();

  @override
  _ProvidedDisclosureScreenState createState() => _ProvidedDisclosureScreenState();
}

class _ProvidedDisclosureScreenState extends State<ProvidedDisclosureScreen> {
  final _lang = 'nl';

  @override
  void initState() {
    widget.sessionStateStream
        .firstWhere((sessionState) => sessionState.candidatesConDisCon != null)
        .then((sessionState) => _showExplanation(sessionState.candidatesConDisCon));

    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: IrmaAppBar(
        title: Text(FlutterI18n.translate(context, 'disclosure.title')),
      ),
      backgroundColor: IrmaTheme.of(context).grayscaleWhite,
      body: StreamBuilder(
          stream: widget.sessionStateStream,
          builder: (BuildContext context, AsyncSnapshot<SessionState> sessionStateSnapshot) {
            if (!sessionStateSnapshot.hasData || sessionStateSnapshot.data.candidatesConDisCon == null) {
              return Container();
            }

            final sessionState = sessionStateSnapshot.data;

            // TODO: See how disclosure_card.dart fits in here
            return ListView(
              padding: EdgeInsets.all(IrmaTheme.of(context).smallSpacing),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: IrmaTheme.of(context).mediumSpacing, horizontal: IrmaTheme.of(context).smallSpacing),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: FlutterI18n.translate(context, 'disclosure.intro.start'),
                          style: IrmaTheme.of(context).textTheme.body1),
                      TextSpan(
                          text: sessionState.serverName != null ? sessionState.serverName.translate(_lang) : "",
                          style: IrmaTheme.of(context).textTheme.body2),
                      TextSpan(
                          text: FlutterI18n.translate(context, 'disclosure.intro.end'),
                          style: IrmaTheme.of(context).textTheme.body1),
                    ]),
                  ),
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
                      ...sessionState.candidatesConDisCon
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
          }));

  Future<void> _showExplanation(ConDisCon<CredentialAttribute> candidatesConDisCon) async {
    final irmaPrefs = IrmaPreferences.get();

    final bool showDisclosureDialog = await irmaPrefs.getShowDisclosureDialog().first;
    final hasChoice = candidatesConDisCon.any((candidatesDisCon) => candidatesDisCon.length > 1);

    if (showDisclosureDialog && hasChoice) {
      showDialog(
        context: context,
        builder: (BuildContext context) => IrmaDialog(
          title: 'disclosure.explanation.title',
          content: 'disclosure.explanation.body',
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
}
