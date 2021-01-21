import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/issue_wizard.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/models/translated_value.dart';
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
  int _activeItem = 0;
  bool _showIntro = true;
  bool _showSuccess = false;
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

  Widget _buildIntro(BuildContext context, TranslatedValue intro, List<IssueWizardQA> questions) {
    final _collapsableKeys = List<GlobalKey>.generate(questions.length, (int index) => GlobalKey());
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
          child: IrmaMarkdown(intro.translate(lang)),
        ),
        ...questions.asMap().entries.map(
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

  Widget _buildIntroButtons() {
    return IrmaBottomBar(
      primaryButtonLabel: FlutterI18n.translate(context, "issue_wizard.add"),
      onPrimaryPressed: () {
        _repo.wizardActive = true;
        setState(() => _showIntro = false);
      },
      secondaryButtonLabel: FlutterI18n.translate(context, "issue_wizard.back"),
      onSecondaryPressed: () => popToWallet(context),
    );
  }

  Widget _buildWizard(
    BuildContext context,
    TranslatedValue intro,
    TranslatedValue successHeader,
    TranslatedValue successText,
    List<IssueWizardItem> wizard,
  ) {
    assert((successHeader == null) == (successText == null),
        "Either specify both successHeader and successText, or neither.");

    final lang = FlutterI18n.currentLocale(context).languageCode;
    final contents = wizard
        .map((item) => ProgressingListItem(
              header: item.header.translate(lang),
              text: item.text.translate(lang),
              completed: item.completed ?? false,
            ))
        .toList();

    return VisibilityDetector(
      key: const Key('wizard-key'),
      onVisibilityChanged: (v) => _onVisibilityChanged(v, wizard, successText != null),
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
            child: ProgressingList(data: contents, activeItem: activeItem(wizard)),
          ),
          if (_showSuccess)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(successHeader.translate(lang), style: Theme.of(context).textTheme.headline3),
            ),
          if (_showSuccess)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: IrmaMarkdown(successText.translate(lang)),
            ),
        ],
      ),
    );
  }

  int activeItem(List<IssueWizardItem> wizard) =>
      max(_activeItem, wizard.indexWhere((item) => !(item.completed ?? false)));

  Future<void> _onVisibilityChanged(
    VisibilityInfo visibility,
    List<IssueWizardItem> wizard,
    bool successMessage,
  ) async {
    // If we became visible and the session that was started by the currently active wizard item
    // is done and has succeeded, we need to progress to the next item or close the wizard.
    final state = await _repo.getSessionState(_sessionID).first;
    if (!(visibility.visibleFraction > 0.9 && state.status == SessionStatus.success)) {
      return;
    }

    final nextIdx = wizard.indexWhere((item) => !(item.completed ?? false), activeItem(wizard) + 1);
    if (nextIdx != -1) {
      setState(() => _activeItem = nextIdx);
    } else if (successMessage) {
      setState(() {
        _activeItem = wizard.length + 1;
        _showSuccess = true;
      });
    } else {
      _repo.wizardActive = false;
      popToWallet(context);
    }
  }

  void _onButtonPress(
    BuildContext context,
    List<IssueWizardItem> wizard,
    bool successMessage,
  ) {
    if (_showSuccess) {
      _repo.wizardActive = false;
      popToWallet(context);
      return;
    }

    final idx = activeItem(wizard);
    final item = idx < wizard.length ? wizard[idx] : null;
    if (item != null) {
      // One way or another, the wizard item will start a session. When it does, we save the session ID,
      // so that when the user returns to this screen, we can check if it finished.
      _repo
          .getEvents()
          .where((event) => event is NewSessionEvent)
          .first
          .then((event) => _sessionID = (event as SessionEvent).sessionID);

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
            _repo.openURL(context, getTranslation(context, item.url));
            break;
        }
      } on PlatformException catch (e, stacktrace) {
        // TODO error screen
        reportError(e, stacktrace);
      }
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

        final wizard = snapshot.data.wizard;
        final contents = snapshot.data.wizardContents;
        final idx = activeItem(contents);
        final buttonLabel = _showSuccess
            ? FlutterI18n.translate(context, "issue_wizard.done")
            : contents[idx].label?.translate(lang) ??
                FlutterI18n.translate(
                  context,
                  "issue_wizard.add_credential",
                  translationParams: {"credential": contents[idx].header.translate(lang)},
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
              ? _buildIntroButtons()
              : IrmaBottomBar(
                  primaryButtonLabel: buttonLabel,
                  onPrimaryPressed: () => _onButtonPress(context, contents, wizard.successHeader != null),
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
                    if (_showIntro)
                      _buildIntro(context, wizard.info, wizard.faq)
                    else
                      _buildWizard(context, wizard.intro, wizard.successHeader, wizard.successText, contents),
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
