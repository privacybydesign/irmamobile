import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/irma_repository.dart';
import '../../models/authentication_events.dart';
import '../../models/enrollment_events.dart';
import '../../models/error_event.dart';
import '../../models/irma_configuration.dart';
import '../../models/scheme_events.dart';
import '../../theme/theme.dart';
import '../../util/combine.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_button.dart';
import '../../widgets/irma_dialog.dart';
import '../../widgets/irma_icon_button.dart';
import '../../widgets/loading_indicator.dart';
import '../enrollment/provide_email/provide_email_screen.dart';
import '../error/error_screen.dart';
import '../pin/yivi_pin_screen.dart';

class ManageSchemesScreen extends StatefulWidget {
  final IrmaRepository irmaRepository;

  const ManageSchemesScreen({Key? key, required this.irmaRepository}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ManageSchemesScreenState();
}

class _ManageSchemesScreenState extends State<ManageSchemesScreen> {
  StreamSubscription? _errorSubscription;

  NavigatorState? get navigator => mounted ? Navigator.of(context) : null;

  @override
  void initState() {
    super.initState();
    widget.irmaRepository.automaticErrorReporting = false;
    _errorSubscription = widget.irmaRepository.getEvents().whereType<ErrorEvent>().listen((event) {
      navigator?.push(MaterialPageRoute(
        builder: (context) => ErrorScreen.fromEvent(
          error: event,
          onTapClose: () => navigator?.pop(),
        ),
      ));
    });
  }

  @override
  void dispose() {
    widget.irmaRepository.automaticErrorReporting = true;
    _errorSubscription?.cancel();
    super.dispose();
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
      ));
    }
  }

  Future<String?> _requestPin(String title, String instruction) async {
    final hasLongPin = await widget.irmaRepository.preferences.getLongPin().first;
    final maxPinSize = hasLongPin ? 16 : 5;

    return navigator?.push(
      MaterialPageRoute(
        builder: (context) => YiviPinScaffold(
          appBar: IrmaAppBar(title: title),
          body: YiviPinScreen(
            instruction: instruction,
            pinBloc: EnterPinStateBloc(maxPinSize),
            maxPinSize: maxPinSize,
            onSubmit: (pin) => navigator?.pop(pin),
            listener: (context, state) {
              if (!hasLongPin && state.pin.length == 5) {
                navigator?.pop(state.toString());
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _installScheme() async {
    final theme = IrmaTheme.of(context);
    final url = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return IrmaDialog(
          title: 'Install scheme',
          content: 'Enter the URL of the scheme that should be installed:',
          child: Wrap(
            runSpacing: theme.defaultSpacing,
            alignment: WrapAlignment.center,
            children: [
              TextField(
                controller: controller,
                autocorrect: false,
                autofocus: true,
                onSubmitted: (url) => navigator?.pop(url),
              ),
              IrmaButton(
                label: 'Install',
                onPressed: () => navigator?.pop(controller.text),
              ),
            ],
          ),
        );
      },
    );
    if (url == null) return;

    String publicKey = '';
    try {
      final Uri uri = Uri.parse('$url/pk.pem');
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      publicKey = await response.transform(utf8.decoder).first;
      if (response.statusCode != 200) {
        throw 'HTTP status code ${response.statusCode} received';
      }
    } catch (e) {
      _showMessage('Error while fetching scheme: ${e.toString()}.');
      return;
    }

    // Before showing the second dialog, we have to check whether the widget is still mounted.
    if (!mounted) return;

    final publicKeyConfirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return IrmaDialog(
              title: 'Confirm public key',
              content: publicKey,
              child: IrmaButton(
                label: 'Confirm',
                onPressed: () => navigator?.pop(true),
              ),
            );
          },
        ) ??
        false;
    if (!publicKeyConfirmed) return;

    widget.irmaRepository.bridgedDispatch(InstallSchemeEvent(
      url: url,
      publicKey: publicKey,
    ));

    try {
      await widget.irmaRepository
          .getEvents()
          .whereType<EnrollmentStatusEvent>()
          .first
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      // Installing the scheme took too long. We therefore assume that it failed.
      // Error is sent as ErrorEvent and will be handled by listener in initState.
      return;
    }
    _showMessage('Scheme installed successfully.');
  }

  Future<void> _activateScheme(String schemeId) async {
    final language = FlutterI18n.currentLocale(context)?.languageCode ?? 'en';
    final pin = await _requestPin(
      'Activate scheme',
      'Enter PIN to confirm activation of scheme $schemeId',
    );
    if (pin == null) return;

    final email = await navigator?.push(
      MaterialPageRoute(
        builder: (context) => ProvideEmailScreen(
          onEmailProvided: (email) => navigator?.pop(email),
          onEmailSkipped: () => navigator?.pop(''),
          onPrevious: () => navigator?.pop(),
        ),
      ),
    );
    if (email == null) return;

    navigator?.pop();
    _showMessage('Activating $schemeId...');

    widget.irmaRepository.bridgedDispatch(EnrollEvent(
      email: email,
      pin: pin,
      language: language,
      schemeId: schemeId,
    ));

    final event = await widget.irmaRepository.getEvents().whereType<EnrollmentEvent>().first;
    if (event is EnrollmentFailureEvent) {
      navigator?.push(MaterialPageRoute(
        builder: (context) => ErrorScreen(
          details: event.error.toString(),
          onTapClose: () => navigator?.pop(),
        ),
      ));
    } else {
      _showMessage('Scheme $schemeId activated successfully.');
    }
  }

  Future<void> _verifyPin(String schemeId) async {
    final pin = await _requestPin(
      'Verify PIN',
      'Authenticate to keyshare server of scheme $schemeId',
    );
    if (pin == null) return;

    widget.irmaRepository.bridgedDispatch(AuthenticateEvent(pin: pin, schemeId: schemeId));

    final event = await widget.irmaRepository.getEvents().whereType<AuthenticationEvent>().first;
    navigator?.pop();

    if (event is AuthenticationErrorEvent) {
      navigator?.push(MaterialPageRoute(
        builder: (context) => ErrorScreen(
          details: event.error.toString(),
          onTapClose: () => navigator?.pop(),
        ),
      ));
    } else {
      _showMessage(
        event is AuthenticationFailedEvent
            ? 'PIN verification failed (attempts remaining: ${event.remainingAttempts}, blocked: ${event.blockedDuration} seconds).'
            : 'PIN verified successfully.',
      );
    }
  }

  void _removeScheme(String schemeId) {
    widget.irmaRepository.bridgedDispatch(RemoveSchemeEvent(schemeId: schemeId));
    navigator?.pop();
    _showMessage('Removing $schemeId...');
  }

  Future<void> _showSchemeManagerDetailsDialog(
    SchemeManager schemeManager, {
    required bool isActive,
  }) {
    final theme = IrmaTheme.of(context);
    return showDialog(
      context: context,
      builder: (context) => IrmaDialog(
        title: 'Issuer scheme ${schemeManager.id}',
        content: [
          schemeManager.demo ? 'Demo scheme' : 'Production scheme',
          if (schemeManager.id == widget.irmaRepository.defaultKeyshareScheme) 'Default keyshare scheme',
          '',
          'Scheme URL:',
          schemeManager.url,
          '',
          'Keyshare server:',
          schemeManager.keyshareServer.isNotEmpty ? schemeManager.keyshareServer : '(none)',
        ].join('\n'),
        child: Wrap(
          runSpacing: theme.defaultSpacing,
          alignment: WrapAlignment.center,
          children: [
            if (!isActive)
              IrmaButton(
                label: 'Activate',
                onPressed: () => _activateScheme(schemeManager.id),
              ),
            if (isActive && schemeManager.keyshareServer.isNotEmpty)
              IrmaButton(
                label: 'Verify PIN',
                onPressed: () => _verifyPin(schemeManager.id),
              ),
            // irmago cannot remove inactive schemes and schemes without a keyshare server yet.
            // https://github.com/privacybydesign/irmago/issues/260
            if (isActive &&
                schemeManager.keyshareServer.isNotEmpty &&
                schemeManager.id != widget.irmaRepository.defaultKeyshareScheme)
              IrmaButton(
                label: 'Remove',
                onPressed: () => _removeScheme(schemeManager.id),
              ),
          ],
        ),
      ),
    );
  }

  _buildSchemeManagerTile(SchemeManager schemeManager, {required bool isActive}) {
    final theme = IrmaTheme.of(context);
    return ListTile(
      title: Text(schemeManager.id),
      subtitle: Text(
        isActive ? 'Active scheme' : 'Inactive scheme',
        style: theme.textTheme.caption,
      ),
      onTap: () => _showSchemeManagerDetailsDialog(schemeManager, isActive: isActive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'Manage schemes',
        leadingAction: () => navigator?.pop(),
        leadingIcon: Icon(Icons.arrow_back, semanticLabel: FlutterI18n.translate(context, 'accessibility.back')),
        actions: [
          IrmaIconButton(
            icon: Icons.add,
            onTap: () => _installScheme(),
          ),
        ],
      ),
      body: StreamBuilder<CombinedState2<EnrollmentStatusEvent, IrmaConfiguration>>(
        stream: combine2(
          widget.irmaRepository.getEnrollmentStatusEvent(),
          widget.irmaRepository.getIrmaConfiguration(),
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LoadingIndicator();
          final enrollmentStatus = snapshot.data!.a;
          final irmaConfiguration = snapshot.data!.b;

          return ListView(
            padding: EdgeInsets.all(theme.defaultSpacing),
            children: [
              const Text("Issuer schemes:"),
              for (final schemeManager in irmaConfiguration.schemeManagers.values)
                _buildSchemeManagerTile(
                  schemeManager,
                  isActive: !enrollmentStatus.unenrolledSchemeManagerIds.contains(schemeManager.id),
                ),
              const Text("Requestor schemes:"),
              // irmago cannot remove requestor schemes schemes yet.
              // https://github.com/privacybydesign/irmago/issues/260
              for (final schemeId in irmaConfiguration.requestorSchemes.keys)
                ListTile(
                  title: Text(schemeId),
                  subtitle: Text('Cannot be edited yet', style: theme.textTheme.caption),
                ),
            ],
          );
        },
      ),
    );
  }
}
