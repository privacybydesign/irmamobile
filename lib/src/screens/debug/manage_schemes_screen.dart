import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/authentication_events.dart';
import 'package:irmamobile/src/screens/enrollment/provide_email/provide_email_screen.dart';
import 'package:irmamobile/src/screens/error/error_screen.dart';
import 'package:irmamobile/src/screens/pin/yivi_pin_screen.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/enrollment_events.dart';
import '../../models/irma_configuration.dart';
import '../../models/scheme_events.dart';
import '../../theme/theme.dart';
import '../../util/combine.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_icon_button.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/loading_indicator.dart';

class ManageSchemesScreen extends StatelessWidget {
  Future<String?> _requestPin(BuildContext context, String title, String instruction) async {
    final navigator = Navigator.of(context);
    final repo = IrmaRepositoryProvider.of(context);
    final hasLongPin = await repo.preferences.getLongPin().first;
    final maxPinSize = hasLongPin ? 16 : 5;

    return navigator.push(
      MaterialPageRoute(
        builder: (context) => YiviPinScaffold(
          appBar: IrmaAppBar(title: title),
          body: YiviPinScreen(
            instruction: instruction,
            pinBloc: EnterPinStateBloc(maxPinSize),
            maxPinSize: maxPinSize,
            onSubmit: (pin) => navigator.pop(pin),
            listener: (context, state) {
              if (!hasLongPin && state.pin.length == 5) {
                navigator.pop(state.toString());
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _activateScheme(BuildContext context, String schemeId) async {
    final navigator = Navigator.of(context);
    final repo = IrmaRepositoryProvider.of(context);

    final pin = await _requestPin(
      context,
      'Activate scheme',
      'Enter PIN to confirm activation of scheme "$schemeId"',
    );
    if (pin == null) return;

    final email = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProvideEmailScreen(
          onEmailProvided: (email) => navigator.pop(email),
          onEmailSkipped: () => navigator.pop(''),
          onPrevious: () => navigator.pop(),
        ),
      ),
    );
    if (email == null) return;

    repo.bridgedDispatch(EnrollEvent(
      email: email,
      pin: pin,
      language: FlutterI18n.currentLocale(context)?.languageCode ?? 'en',
      schemeId: schemeId,
    ));

    Navigator.of(context).pop();
  }

  Future<void> _verifyPin(BuildContext context, String schemeId) async {
    final navigator = Navigator.of(context);
    final repo = IrmaRepositoryProvider.of(context);
    final pin = await _requestPin(
      context,
      'Verify PIN',
      'Authenticate to keyshare server of scheme $schemeId',
    );
    if (pin == null) return;

    repo.bridgedDispatch(AuthenticateEvent(pin: pin, schemeId: schemeId));

    final event = await repo.getEvents().whereType<AuthenticationEvent>().first;
    navigator.pop();

    if (event is AuthenticationErrorEvent) {
      navigator.push(MaterialPageRoute(
        builder: (context) => ErrorScreen(
          details: event.error.toString(),
          onTapClose: () => navigator.pop(),
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          event is AuthenticationFailedEvent
              ? 'PIN verification failed (attempts remaining: ${event.remainingAttempts}, blocked: ${event.blockedDuration} seconds)'
              : 'PIN verified successfully',
        ),
      ));
    }
  }

  Future<void> _editSchemeDialog(
    BuildContext context,
    String schemeId, {
    bool canActivate = false,
    bool canVerifyPin = false,
    bool canRemove = false,
  }) {
    final repo = IrmaRepositoryProvider.of(context);
    final theme = IrmaTheme.of(context);
    return showDialog(
      context: context,
      builder: (context) => IrmaDialog(
        title: 'Edit scheme',
        content: 'Possible actions for $schemeId:',
        child: Wrap(
          runSpacing: theme.defaultSpacing,
          alignment: WrapAlignment.center,
          children: [
            if (canActivate)
              IrmaButton(
                label: 'Activate',
                onPressed: () => _activateScheme(context, schemeId),
              ),
            if (canVerifyPin)
              IrmaButton(
                label: 'Verify PIN',
                onPressed: () => _verifyPin(context, schemeId),
              ),
            if (canRemove)
              IrmaButton(
                label: 'Remove',
                onPressed: () {
                  repo.bridgedDispatch(RemoveSchemeEvent(schemeId: schemeId));
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _installScheme(BuildContext context) async {
    final navigator = Navigator.of(context);
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
                onSubmitted: (url) => navigator.pop(url),
              ),
              IrmaButton(
                label: 'Install',
                onPressed: () => navigator.pop(controller.text),
              ),
            ],
          ),
        );
      },
    );
    if (url == null) return;

    final Uri uri = Uri.parse('$url/pk.pem');
    final request = await HttpClient().getUrl(uri);
    final response = await request.close();
    final publicKey = await response.transform(utf8.decoder).first;
    if (response.statusCode != 200) return;

    final publicKeyConfirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return IrmaDialog(
              title: 'Confirm public key',
              content: publicKey,
              child: IrmaButton(
                label: 'Confirm',
                onPressed: () => navigator.pop(true),
              ),
            );
          },
        ) ??
        false;
    if (!publicKeyConfirmed) return;

    final repo = IrmaRepositoryProvider.of(context);
    repo.bridgedDispatch(InstallSchemeEvent(
      url: url,
      publicKey: publicKey,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);
    final theme = IrmaTheme.of(context);
    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'Manage schemes',
        leadingAction: () => Navigator.of(context).pop(),
        leadingIcon: Icon(Icons.arrow_back, semanticLabel: FlutterI18n.translate(context, 'accessibility.back')),
        actions: [
          IrmaIconButton(
            icon: Icons.add,
            onTap: () => _installScheme(context),
          ),
        ],
      ),
      body: StreamBuilder<CombinedState2<EnrollmentStatusEvent, IrmaConfiguration>>(
        stream: combine2(repo.getEnrollmentStatusEvent(), repo.getIrmaConfiguration()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LoadingIndicator();
          final enrollmentStatus = snapshot.data!.a;
          final irmaConfiguration = snapshot.data!.b;

          // The demo flag can also be set for keyshare schemes, so we have to look at the keyshareServer field
          final demoSchemes = irmaConfiguration.schemeManagers.entries
              .where((entry) => entry.value.keyshareServer.isEmpty)
              .map((entry) => entry.key);
          final nonDefaultEnrolledSchemes =
              enrollmentStatus.enrolledSchemeManagerIds.where((schemeId) => schemeId != repo.defaultKeyshareScheme);

          return ListView(
            padding: EdgeInsets.all(theme.defaultSpacing),
            children: [
              const Text('Active schemes:'),
              ListTile(
                title: Text(repo.defaultKeyshareScheme),
                subtitle: Text('Default keyshare scheme', style: theme.textTheme.caption),
                onTap: () => _editSchemeDialog(context, repo.defaultKeyshareScheme, canVerifyPin: true),
              ),
              for (final schemeId in demoSchemes)
                ListTile(
                  title: Text(schemeId),
                  // TODO: irmago cannot uninstall demo schemes yet.
                  subtitle: Text('Demo scheme (cannot be edited yet)', style: theme.textTheme.caption),
                ),
              for (final schemeId in nonDefaultEnrolledSchemes)
                ListTile(
                  title: Text(schemeId),
                  subtitle: Text('Keyshare scheme', style: theme.textTheme.caption),
                  onTap: () => _editSchemeDialog(context, schemeId, canVerifyPin: true, canRemove: true),
                ),
              if (enrollmentStatus.unenrolledSchemeManagerIds.isNotEmpty) const Text('Inactive schemes:'),
              for (final schemeId in enrollmentStatus.unenrolledSchemeManagerIds)
                ListTile(
                  title: Text(schemeId),
                  subtitle: Text('Keyshare scheme', style: theme.textTheme.caption),
                  // TODO: irmago cannot uninstall inactive schemes yet.
                  onTap: () => _editSchemeDialog(context, schemeId, canActivate: true),
                ),
            ],
          );
        },
      ),
    );
  }
}
