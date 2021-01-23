import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/issue_wizard.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/issue_wizard/widgets/progressing_list.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/session/session.dart';
import 'package:irmamobile/src/sentry/sentry.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/collapsible_helper.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/collapsible.dart';
import 'package:irmamobile/src/widgets/heading.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_markdown.dart';
import 'package:irmamobile/src/widgets/logo_banner.dart';
import 'package:visibility_detector/visibility_detector.dart';

void popToWizard(BuildContext context) {
  Navigator.of(context).popUntil(
    ModalRoute.withName(
      IssueWizardScreen.routeName,
    ),
  );
}

class IssueWizardScreen extends StatefulWidget {
  static const routeName = "/issuewizard";

  final String id;
  const IssueWizardScreen({Key key, @required this.id}) : super(key: key);

  @override
  _IssueWizardScreenState createState() => _IssueWizardScreenState();
}

class _IssueWizardScreenState extends State<IssueWizardScreen> {
  bool _showIntro = true;
  int _sessionID;

  final GlobalKey _scrollviewKey = GlobalKey();
  final ScrollController _controller = ScrollController();
  final _repo = IrmaRepository.get();

  Widget _buildCollapsible(BuildContext context, GlobalKey key, String header, String body) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
      child: Collapsible(
        header: header,
        onExpansionChanged: (v) => {if (v) jumpToCollapsable(_controller, _scrollviewKey, key)},
        content: SizedBox(width: double.infinity, child: IrmaMarkdown(body)),
        key: key,
      ),
    );
  }

  Widget _buildIntro(BuildContext context, IssueWizard wizard) {
    final _collapsableKeys = List<GlobalKey>.generate(wizard.faq.length, (int index) => GlobalKey());
    final lang = FlutterI18n.currentLocale(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(
            IrmaTheme.of(context).defaultSpacing,
            0,
            IrmaTheme.of(context).defaultSpacing,
            IrmaTheme.of(context).defaultSpacing,
          ),
          child: IrmaMarkdown(wizard.intro.translate(lang)),
        ),
        ...wizard.faq.asMap().entries.map(
              (q) => _buildCollapsible(
                context,
                _collapsableKeys[q.key],
                q.value.question.translate(lang),
                q.value.answer.translate(lang),
              ),
            )
      ],
    );
  }

  Widget _buildWizard(
    BuildContext context,
    IssueWizardEvent event,
  ) {
    final lang = FlutterI18n.currentLocale(context).languageCode;
    final contents = event.wizardContents
        .map((item) => ProgressingListItem(
              header: item.header.translate(lang),
              text: item.text.translate(lang),
              completed: item.completed ?? false,
            ))
        .toList();

    final successHeader = event.wizard.successHeader;
    final successText = event.wizard.successText;
    final intro = event.wizard.intro;
    return VisibilityDetector(
      key: const Key('wizard-key'),
      onVisibilityChanged: (v) => _onVisibilityChanged(v, event),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (intro != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: IrmaMarkdown(intro.translate(lang)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: ProgressingList(data: contents),
          ),
          if (successHeader != null && event.completed)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(successHeader.translate(lang), style: Theme.of(context).textTheme.headline3),
            ),
          if (successText != null && event.completed)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: IrmaMarkdown(successText.translate(lang)),
            ),
        ],
      ),
    );
  }

  Future<void> _onVisibilityChanged(VisibilityInfo visibility, IssueWizardEvent event) async {
    if (_sessionID == null) return;

    // If we became visible and the session that was started by the currently active wizard item
    // is done and has succeeded, we need to progress to the next item or close the wizard.
    final state = await _repo.getSessionState(_sessionID).first;
    if (!(visibility.visibleFraction > 0.9 && state.status == SessionStatus.success)) {
      return;
    }

    // we're done tracking this session, prevent it from being handled again if we return again
    _sessionID = null;

    final nextEvent = event.next;
    _repo.getIssueWizard().add(nextEvent);

    if (!nextEvent.showSuccess && nextEvent.completed) {
      _repo.wizardActive = false;
      popToWallet(context);
    }
  }

  void _onButtonPress(BuildContext context, IssueWizardEvent event) {
    if (event.completed) {
      _repo.wizardActive = false;
      popToWallet(context);
      return;
    }

    final item = event.activeItem;
    if (item.type != "credential") {
      // One way or another, the wizard item will start a session. When it does, we save the session ID,
      // so that when the user returns to this screen, we can check if it completed.
      // (In case of items of type credential, we don't need to do this because then the item will be marked
      // as completed when the wallet contents is updated.)
      _repo
          .getEvents()
          .where((event) => event is NewSessionEvent)
          .first
          .then((event) => _sessionID = (event as SessionEvent).sessionID);
    }

    // Handle the different wizard item types
    try {
      switch (item.type) {
        case "credential":
          _repo.openIssueURL(context, item.credential);
          break;
        case "session":
          ScannerScreen.startSessionAndNavigate(
            Navigator.of(context),
            SessionPointer(u: item.sessionURL, irmaqr: "redirect"),
          );
          break;
        case "website":
          item.inApp ?? true
              ? _repo.openURL(context, getTranslation(context, item.url))
              : _repo.openURLinExternalBrowser(context, getTranslation(context, item.url));
          break;
      }
    } on PlatformException catch (e, stacktrace) {
      // TODO error screen
      reportError(e, stacktrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context).languageCode;
    return StreamBuilder(
      stream: _repo.getIssueWizard().where((event) => event.wizard.id == widget.id),
      builder: (context, AsyncSnapshot<IssueWizardEvent> snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        final event = snapshot.data;
        final wizard = event.wizard;
        final activeItem = event.activeItem;
        final buttonLabel = activeItem == null
            ? FlutterI18n.translate(context, "issue_wizard.done")
            : activeItem.label?.translate(lang) ??
                FlutterI18n.translate(
                  context,
                  "issue_wizard.add_credential",
                  translationParams: {"credential": activeItem.header.translate(lang)},
                );
        final logoFile = File(wizard.logoPath ?? "");
        final logo = logoFile.existsSync()
            ? Image.file(logoFile, excludeFromSemantics: true)
            : Image.asset("assets/non-free/irmalogo.png", excludeFromSemantics: true);

        return Scaffold(
          appBar: IrmaAppBar(
            title: Text(FlutterI18n.translate(context, "issue_wizard.add_cards")),
            leadingAction: () {
              _repo.wizardActive = false;
              Navigator.of(context).pop();
            },
            leadingIcon: Icon(Icons.arrow_back, semanticLabel: FlutterI18n.translate(context, "accessibility.back")),
          ),
          bottomNavigationBar: _showIntro
              ? IrmaBottomBar(
                  primaryButtonLabel: FlutterI18n.translate(context, "issue_wizard.add"),
                  onPrimaryPressed: () {
                    _repo.wizardActive = true;
                    setState(() => _showIntro = false);
                  },
                  secondaryButtonLabel: FlutterI18n.translate(context, "issue_wizard.back"),
                  onSecondaryPressed: () => popToWallet(context),
                )
              : IrmaBottomBar(
                  primaryButtonLabel: buttonLabel,
                  onPrimaryPressed: () => _onButtonPress(context, event),
                ),
          body: SingleChildScrollView(
            controller: _controller,
            key: _scrollviewKey,
            child: Column(
              children: <Widget>[
                LogoBanner(logo: logo),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Heading(wizard.title.translate(lang), style: Theme.of(context).textTheme.headline5),
                    ),
                    if (_showIntro) _buildIntro(context, wizard) else _buildWizard(context, event),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
