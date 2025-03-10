import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../data/irma_repository.dart';
import '../../models/issue_wizard.dart';
import '../../models/session.dart';
import '../../models/session_events.dart';
import '../../models/session_state.dart';
import '../../models/translated_value.dart';
import '../../screens/issue_wizard/widgets/wizard_contents.dart';
import '../../screens/issue_wizard/widgets/wizard_info.dart';
import '../../util/handle_pointer.dart';
import '../../util/language.dart';
import '../../util/navigation.dart';
import '../../widgets/irma_repository_provider.dart';
import 'widgets/issue_wizard_success_screen.dart';

class IssueWizardScreen extends StatefulWidget {
  static const routeName = '/issuewizard';

  final IssueWizardScreenArguments arguments;

  const IssueWizardScreen({super.key, required this.arguments});

  @override
  State<IssueWizardScreen> createState() => _IssueWizardScreenState();
}

class IssueWizardScreenArguments {
  final String wizardID;
  final int? sessionID;

  IssueWizardScreenArguments({required this.wizardID, required this.sessionID});
}

class _IssueWizardScreenState extends State<IssueWizardScreen> with WidgetsBindingObserver {
  bool _showIntro = true;
  int? _sessionID;
  StreamSubscription<SessionState>? _sessionSubscription;

  final GlobalKey _scrollviewKey = GlobalKey();
  final ScrollController _controller = ScrollController();
  late final IrmaRepository _repo;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.arguments.sessionID != null && AppLifecycleState.resumed == state) {
      _sessionSubscription = _repo
          .getSessionState(widget.arguments.sessionID!)
          .firstWhere((event) => event.isFinished)
          .asStream()
          .listen((event) {
        // Pop to underlying session screen which is showing an error screen
        // First pop all screens on top of this wizard and then pop the wizard screen itself
        if (mounted) {
          Navigator.of(context)
            ..popUntil(ModalRoute.withName(IssueWizardScreen.routeName))
            ..pop();
        }
      });
    }

    super.didChangeAppLifecycleState(state);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // only init it once... this will throw an error when we're accessing an uninitialized one,
    // we then catch that and assign a value.
    // we can't do this in initState because it doesn't have access to the BuildContext.
    try {
      _repo;
    } catch (_) {
      _repo = IrmaRepositoryProvider.of(context);
    }
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _repo.getIssueWizardActive().add(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _finish(IssueWizardEvent wizard) async {
    final activeSessions = await _repo.hasActiveSessions();
    if (!mounted) {
      return; // can't do anything if our context vanished while awaiting
    }

    final navigator = Navigator.of(context);
    if (activeSessions) {
      // Pop to underlying session screen
      navigator.pop();
    } else {
      // Show the success screen with success text if there is one.
      TranslatedValue? successHeaderTranslation;
      TranslatedValue? successContentTranslation;

      if (wizard.showSuccess) {
        successHeaderTranslation = wizard.wizardData.successHeader;
        successContentTranslation = wizard.wizardData.successText;
      }

      await navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => IssueWizardSuccessScreen(
            headerTranslation: successHeaderTranslation,
            contentTranslation: successContentTranslation,
            onDismiss: () => popToHome(context),
          ),
        ),
      );
    }
  }

  Future<void> _onVisibilityChanged(VisibilityInfo visibility, IssueWizardEvent wizard) async {
    if (_sessionID == null) return;

    // If we became visible and the session that was started by the currently active wizard item
    // is done and has succeeded, we need to progress to the next item or close the wizard.
    final state = await _repo.getSessionState(_sessionID!).first;
    if (!(visibility.visibleFraction > 0.9 && state.status == SessionStatus.success)) {
      return;
    }

    // we're done tracking this session, prevent it from being handled again if we return again
    _sessionID = null;

    final nextEvent = wizard.nextEvent;
    _repo.getIssueWizard().add(nextEvent);

    if (!nextEvent.showSuccess && nextEvent.completed) {
      await _finish(wizard);
    }
  }

  void _onButtonPress(BuildContext context, IssueWizardEvent wizard) {
    if (wizard.completed) {
      _finish(wizard);
      return;
    }

    final item = wizard.activeItem;
    if (item?.credential == null) {
      // If it is not known in advance which credential a wizard item will issue (if it issues anything at all),
      // then the only reasonable condition that we can use to consider the item to be completed is whenever the
      // session that it starts has finished successfully. So when the session starts, we save the session ID,
      // so that when the user returns to this screen, we can check if it completed.
      _repo
          .getEvents()
          .where((event) => event is NewSessionEvent)
          .first
          .then((event) => _sessionID = (event as SessionEvent).sessionID);
    }

    // Handle the different wizard item types
    switch (item?.type) {
      case 'credential':
        _repo.openIssueURL(context, item?.credential ?? '');
        break;
      case 'session':
        handlePointer(
          Navigator.of(context),
          SessionPointer(u: item?.sessionURL ?? '', irmaqr: 'redirect'),
        );
        break;
      case 'website':
        item?.inApp ?? true
            ? _repo.openURL(getTranslation(context, item?.url ?? const TranslatedValue.empty()))
            : _repo.openURLExternally(getTranslation(context, item?.url ?? const TranslatedValue.empty()));
        break;
    }
  }

  void _onBackPress() {
    popToHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _repo.getIssueWizard().where((event) => event?.wizardData.id == widget.arguments.wizardID),
      builder: (context, AsyncSnapshot<IssueWizardEvent?> snapshot) {
        if (!snapshot.hasData) {
          return Container(
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        final wizard = snapshot.data;
        final wizardData = wizard?.wizardData;
        final logoFile = File(wizardData?.logoPath ?? '');
        final logo = logoFile.existsSync()
            ? Image.file(logoFile, excludeFromSemantics: true)
            : Image.asset('assets/non-free/irmalogo.png', excludeFromSemantics: true);

        if (_showIntro) {
          return IssueWizardInfo(
            scrollviewKey: _scrollviewKey,
            controller: _controller,
            logo: logo,
            wizardData: wizardData!,
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
            wizard: wizard!,
            onBack: _onBackPress,
            onNext: _onButtonPress,
            onVisibilityChanged: _onVisibilityChanged,
          );
        }
      },
    );
  }
}
