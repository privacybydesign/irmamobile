import 'dart:io';

import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/issue_wizard.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/screens/issue_wizard/widgets/wizard_contents.dart';
import 'package:irmamobile/src/screens/issue_wizard/widgets/wizard_info.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/session/session.dart';
import 'package:irmamobile/src/util/language.dart';
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

  final String wizardID;
  const IssueWizardScreen({Key key, @required this.wizardID}) : super(key: key);

  @override
  _IssueWizardScreenState createState() => _IssueWizardScreenState();
}

class _IssueWizardScreenState extends State<IssueWizardScreen> {
  bool _showIntro = true;
  int _sessionID;

  final GlobalKey _scrollviewKey = GlobalKey();
  final ScrollController _controller = ScrollController();
  final _repo = IrmaRepository.get();

  @override
  void dispose() {
    _repo.getIssueWizardActive().add(false);
    super.dispose();
  }

  Future<void> _finish() async {
    final activeSessions = await IrmaRepository.get().hasActiveSessions();
    if (!mounted) {
      return; // can't do anything if our context vanished while awaiting
    }
    if (activeSessions) {
      // Pop to underlying session screen
      Navigator.of(context).pop();
    } else {
      popToWallet(context);
    }
  }

  Future<void> _onVisibilityChanged(VisibilityInfo visibility, IssueWizardEvent wizard) async {
    if (_sessionID == null) return;

    // If we became visible and the session that was started by the currently active wizard item
    // is done and has succeeded, we need to progress to the next item or close the wizard.
    final state = await _repo.getSessionState(_sessionID).first;
    if (!(visibility.visibleFraction > 0.9 && state.status == SessionStatus.success)) {
      return;
    }

    // we're done tracking this session, prevent it from being handled again if we return again
    _sessionID = null;

    final nextEvent = wizard.nextEvent;
    _repo.getIssueWizard().add(nextEvent);

    if (!nextEvent.showSuccess && nextEvent.completed) {
      await _finish();
    }
  }

  void _onButtonPress(BuildContext context, IssueWizardEvent wizard) {
    if (wizard.completed) {
      _finish();
      return;
    }

    final item = wizard.activeItem;
    if (item.credential == null) {
      // If it is not known in advance which credential a wizard item will issue (if it issues anything at all),
      // then the only reasonable condition that we can use to consider the item to be completed is whenenver the
      // session that it starts has finished succesfully. So when the session starts, we save the session ID,
      // so that when the user returns to this screen, we can check if it completed.
      _repo
          .getEvents()
          .where((event) => event is NewSessionEvent)
          .first
          .then((event) => _sessionID = (event as SessionEvent).sessionID);
    }

    // Handle the different wizard item types
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
  }

  void _onBackPress() {
    popToWallet(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _repo.getIssueWizard().where((event) => event.wizardData.id == widget.wizardID),
      builder: (context, AsyncSnapshot<IssueWizardEvent> snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        final wizard = snapshot.data;
        final wizardData = wizard.wizardData;
        final logoFile = File(wizardData.logoPath ?? "");
        final logo = logoFile.existsSync()
            ? Image.file(logoFile, excludeFromSemantics: true)
            : Image.asset("assets/non-free/irmalogo.png", excludeFromSemantics: true);

        if (_showIntro) {
          return IssueWizardInfo(
            scrollviewKey: _scrollviewKey,
            controller: _controller,
            logo: logo,
            wizardData: wizardData,
            onBack: _onBackPress,
            onNext: () {
              _repo.getIssueWizardActive().add(true);
              setState(() => _showIntro = false);
            },
          );
        } else {
          return IssueWizardContents(
            scrollviewKey: _scrollviewKey,
            controller: _controller,
            logo: logo,
            wizard: wizard,
            onBack: _onBackPress,
            onNext: _onButtonPress,
            onVisibilityChanged: _onVisibilityChanged,
          );
        }
      },
    );
  }
}
