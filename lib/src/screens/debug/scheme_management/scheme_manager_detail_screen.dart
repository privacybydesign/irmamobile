import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:rxdart/rxdart.dart';

import '../../../models/authentication_events.dart';
import '../../../models/enrollment_events.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/scheme_events.dart';
import '../../../providers/irma_repository_provider.dart';
import '../../../theme/theme.dart';
import '../../../util/combine.dart';
import '../../../widgets/active_indicator.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/irma_icon_button.dart';
import '../../../widgets/progress.dart';
import '../../enrollment/provide_email/provide_email_screen.dart';
import '../../error/error_screen.dart';
import '../../pin/yivi_pin_screen.dart';
import '../util/snackbar.dart';

class SchemeManagerDetailScreen extends StatelessWidget {
  final String schemeManagerId;

  const SchemeManagerDetailScreen(
    this.schemeManagerId,
  );

  Future<String?> _requestPin(BuildContext context, String title, String instruction) async {
    final repo = IrmaRepositoryProvider.of(context);
    final navigator = Navigator.of(context);

    final hasLongPin = await repo.preferences.getLongPin().first;
    final maxPinSize = hasLongPin ? 16 : 5;

    return navigator.push(
      MaterialPageRoute(
        builder: (context) => YiviPinScaffold(
          appBar: IrmaAppBar(title: title, hasBorder: false),
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

  Future<void> _verifyPin(BuildContext context, String schemeId) async {
    final repo = IrmaRepositoryProvider.of(context);
    final navigator = Navigator.of(context);

    final pin = await _requestPin(
      context,
      FlutterI18n.translate(context, 'debug.scheme_management.verify_pin.title'),
      FlutterI18n.translate(
        context,
        'debug.scheme_management.verify_pin.content',
        translationParams: {
          'scheme': schemeManagerId,
        },
      ),
    );
    if (pin == null) return;

    repo.bridgedDispatch(AuthenticateEvent(pin: pin, schemeId: schemeId));

    final event = await repo.getEvents().whereType<AuthenticationEvent>().first;

    if (event is AuthenticationErrorEvent) {
      navigator.push(MaterialPageRoute(
        builder: (context) => ErrorScreen(
          details: event.error.toString(),
          onTapClose: () => navigator.pop(),
        ),
      ));
    } else {
      if (!context.mounted) return;
      showSnackbar(
        context,
        event is AuthenticationFailedEvent
            ? FlutterI18n.translate(
                context,
                'debug.scheme_management.verify_pin.failed',
                translationParams: {
                  'remainingAttempts': event.remainingAttempts.toString(),
                  'blockedDuration': event.blockedDuration.toString(),
                },
              )
            : FlutterI18n.translate(context, 'debug.scheme_management.verify_pin.success'),
      );
    }
  }

  Future<void> _onActivateScheme(BuildContext context) async {
    final language = FlutterI18n.currentLocale(context)?.languageCode ?? 'en';

    final pin = await _requestPin(
      context,
      FlutterI18n.translate(context, 'debug.scheme_management.request_pin.title'),
      FlutterI18n.translate(
        context,
        'debug.scheme_management.request_pin.content',
        translationParams: {
          'scheme': schemeManagerId,
        },
      ),
    );
    if (pin == null) return;
    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    final email = await navigator.push(
      MaterialPageRoute(
        builder: (context) => ProvideEmailScreen(
          onEmailProvided: (email) => navigator.pop(email),
          onEmailSkipped: () => navigator.pop(''),
          onPrevious: () => navigator.pop(),
        ),
      ),
    );
    if (email == null) return;
    if (!context.mounted) return;

    showSnackbar(
      context,
      FlutterI18n.translate(
        context,
        'debug.scheme_management.activating',
        translationParams: {
          'scheme': schemeManagerId,
        },
      ),
    );

    final repo = IrmaRepositoryProvider.of(context);
    repo.bridgedDispatch(EnrollEvent(
      email: email,
      pin: pin,
      language: language,
      schemeId: schemeManagerId,
    ));

    final event = await repo.getEvents().whereType<EnrollmentEvent>().first;
    if (event is EnrollmentFailureEvent) {
      navigator.push(MaterialPageRoute(
        builder: (context) => ErrorScreen(
          details: event.error.toString(),
          onTapClose: () => navigator.pop(),
        ),
      ));
    } else {
      if (!context.mounted) return;
      showSnackbar(
        context,
        FlutterI18n.translate(
          context,
          'debug.scheme_management.activate_success',
          translationParams: {
            'scheme': schemeManagerId,
          },
        ),
      );
    }
  }

  void _onDeleteScheme(BuildContext context) {
    IrmaRepositoryProvider.of(context).bridgedDispatch(RemoveSchemeEvent(
      schemeId: schemeManagerId,
    ));
    Navigator.of(context).pop();

    if (!context.mounted) return;
    showSnackbar(
      context,
      FlutterI18n.translate(
        context,
        'debug.scheme_management.remove',
        translationParams: {
          'scheme': schemeManagerId,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);
    final theme = IrmaTheme.of(context);

    return StreamBuilder<CombinedState2<EnrollmentStatusEvent, IrmaConfiguration>>(
      stream: combine2(
        repo.getEnrollmentStatusEvent(),
        repo.getIrmaConfiguration(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: IrmaProgress(),
            ),
          );
        }

        final enrollmentStatus = snapshot.data!.a;
        final irmaConfiguration = snapshot.data!.b;

        // Grab the scheme manager from the configuration.
        final schemeManager = irmaConfiguration.schemeManagers[schemeManagerId];
        if (schemeManager == null) throw Exception('Scheme manager $schemeManagerId not found');

        final schemeIsActive = enrollmentStatus.enrolledSchemeManagerIds.contains(schemeManager.id);

        final appId = repo.credentials.values
            .firstWhereOrNull((cred) => cred.isKeyshareCredential && cred.schemeManager.id == schemeManager.id)
            ?.attributes
            .firstOrNull
            ?.value
            .raw;

        Widget? bottomBar;
        if (schemeManager.keyshareServer.isNotEmpty) {
          if (schemeIsActive) {
            bottomBar = IrmaBottomBar(
              primaryButtonLabel: 'debug.scheme_management.verify_pin.title',
              onPrimaryPressed: () => _verifyPin(context, schemeManager.id),
            );
          } else {
            bottomBar = IrmaBottomBar(
              primaryButtonLabel: 'ui.activate',
              onPrimaryPressed: () => _onActivateScheme(context),
            );
          }
        }

        return Scaffold(
          appBar: IrmaAppBar(
            title: schemeManager.id,
            actions: [
              IrmaIconButton(
                icon: Icons.delete,
                onTap: () => _onDeleteScheme(context),
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(theme.screenPadding),
            child: Column(
              children: [
                // These values are not translated because they are the same in English and Dutch.
                if (!schemeManager.demo)
                  ListTile(
                    title: const Text('Status'),
                    trailing: ActiveIndicator(schemeIsActive),
                  ),

                ListTile(
                  title: const Text('Type'),
                  subtitle: Text(schemeManager.demo ? 'Demo scheme' : 'Production scheme'),
                ),

                ListTile(
                  title: const Text('Keyshare server'),
                  subtitle: Text(schemeManager.keyshareServer.isNotEmpty ? schemeManager.keyshareServer : '(none)'),
                ),

                ListTile(
                  title: const Text('App ID'),
                  subtitle: Text(appId ?? '(none)'),
                )
              ],
            ),
          ),
          bottomNavigationBar: bottomBar,
        );
      },
    );
  }
}
