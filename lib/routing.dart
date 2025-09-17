import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';

import 'src/data/irma_repository.dart';
import 'src/models/enrollment_status.dart';
import 'src/models/irma_configuration.dart';
import 'src/models/log_entry.dart';
import 'src/models/translated_value.dart';
import 'src/models/version_information.dart';
import 'src/providers/irma_repository_provider.dart';
import 'src/providers/passport_repository_provider.dart';
import 'src/screens/activity/activity_detail_screen.dart';
import 'src/screens/add_data/add_data_details_screen.dart';
import 'src/screens/add_data/add_data_screen.dart';
import 'src/screens/change_language/change_language_screen.dart';
import 'src/screens/change_pin/change_pin_screen.dart';
import 'src/screens/data/credentials_details_screen.dart';
import 'src/screens/debug/debug_screen.dart';
import 'src/screens/enrollment/enrollment_screen.dart';
import 'src/screens/error/error_screen.dart';
import 'src/screens/help/help_screen.dart';
import 'src/screens/home/home_screen.dart';
import 'src/screens/home/widgets/irma_qr_scan_button.dart';
import 'src/screens/issue_wizard/issue_wizard.dart';
import 'src/screens/issue_wizard/widgets/issue_wizard_success_screen.dart';
import 'src/screens/loading/loading_screen.dart';
import 'src/screens/name_changed/name_changed_screen.dart';
import 'src/screens/notifications/notifications_tab.dart';
import 'src/screens/passport/manual_entry_screen.dart';
import 'src/screens/passport/mrz_reader_screen.dart';
import 'src/screens/passport/nfc_reading_screen.dart';
import 'src/screens/pin/pin_screen.dart';
import 'src/screens/required_update/required_update_screen.dart';
import 'src/screens/reset_pin/reset_pin_screen.dart';
import 'src/screens/rooted_warning/repository.dart';
import 'src/screens/rooted_warning/rooted_warning_screen.dart';
import 'src/screens/scanner/scanner_screen.dart';
import 'src/screens/session/session_screen.dart';
import 'src/screens/session/unknown_session_screen.dart';
import 'src/screens/settings/settings_screen.dart';
import 'src/screens/terms_changed/terms_changed_dialog.dart';
import 'src/util/navigation.dart';
import 'src/widgets/irma_app_bar.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(BuildContext buildContext, WidgetRef ref) {
  final repo = IrmaRepositoryProvider.of(buildContext);
  final redirectionTriggers = RedirectionListenable(repo);

  final whiteListedOnLocked = {'/reset_pin', '/loading', '/enrollment', '/scanner', '/modal_pin'};

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: [routeObserver],
    initialLocation: '/loading',
    refreshListenable: redirectionTriggers,
    errorBuilder: (context, state) => RouteNotFoundScreen(),
    routes: [
      GoRoute(
        path: '/scanner',
        builder: (context, state) {
          final requireAuth = bool.parse(state.uri.queryParameters['require_auth_before_session']!);
          return ScannerScreen(requireAuthBeforeSession: requireAuth);
        },
      ),
      GoRoute(
        path: '/error',
        builder: (context, state) => ErrorScreen(details: state.extra as String, onTapClose: context.pop),
      ),
      GoRoute(
        path: '/loading',
        pageBuilder: (context, state) => NoTransitionPage(name: '/loading', child: LoadingScreen()),
      ),
      GoRoute(
        path: '/pin',
        pageBuilder: (context, state) {
          return NoTransitionPage(
            name: '/pin',
            child: Builder(builder: (context) {
              return TermsChangedListener(
                child: PinScreen(
                  onAuthenticated: context.goHomeScreenWithoutTransition,
                  leading: YiviAppBarQrCodeButton(
                    onTap: () => openQrCodeScanner(
                      context,
                      requireAuthBeforeSession: true,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
      GoRoute(
        path: '/modal_pin',
        builder: (context, state) {
          return PinScreen(
            onAuthenticated: () => context.pop(true),
            leading: YiviBackButton(onTap: () => context.pop(false)),
          );
        },
      ),
      GoRoute(
        path: '/reset_pin',
        builder: (context, state) => ResetPinScreen(),
      ),
      // FIXME: this cannot be a sub route of /home/settings, because it uses its own navigator internally
      GoRoute(
        path: '/change_pin',
        builder: (context, state) => ChangePinScreen(),
      ),
      GoRoute(
        path: '/enrollment',
        builder: (context, state) => EnrollmentScreen(),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          if (TransitionStyleProvider.shouldPerformInstantTransitionToHome(context)) {
            TransitionStyleProvider.resetInstantTransitionToHomeMark(context);
            return NoTransitionPage(name: '/home', child: HomeScreen());
          }
          return MaterialPage(name: '/home', child: HomeScreen());
        },
        routes: [
          GoRoute(
            path: 'credentials_details',
            builder: (context, state) {
              final args = CredentialsDetailsRouteParams.fromQueryParams(state.uri.queryParameters);
              return CredentialsDetailsScreen(categoryName: args.categoryName, credentialTypeId: args.credentialTypeId);
            },
          ),
          GoRoute(
            path: 'activity_details',
            builder: (context, state) {
              final (logEntry, irmaConfiguration) = state.extra as (LogInfo, IrmaConfiguration);
              return ActivityDetailsScreen(
                args: ActivityDetailsScreenArgs(logEntry: logEntry, irmaConfiguration: irmaConfiguration),
              );
            },
          ),
          GoRoute(
            path: 'help',
            builder: (context, state) => HelpScreen(),
          ),
          GoRoute(
            path: 'add_data',
            builder: (context, state) => AddDataScreen(),
            routes: [
              GoRoute(
                path: 'details',
                builder: (context, state) {
                  final credentialType = state.extra as CredentialType;
                  return AddDataDetailsScreen(
                    credentialType: credentialType,
                    onCancel: context.pop,
                    onAdd: () {
                      if (credentialType.id == 'passport') {
                        var url = credentialType.issueUrl.values.first;
                        if (url.isNotEmpty) {
                          var uri = Uri.parse(url);

                          var baseUri = Uri(
                            scheme: uri.scheme,
                            host: uri.host,
                            port: uri.hasPort ? uri.port : null,
                          );

                          final repo = ref.read(passportRepositoryProvider);
                          repo.hostName = baseUri.toString();
                          // Open the MzrReaderScreen
                          context.pushPassportMrzReaderScreen();
                          return;
                        }
                      }
                      IrmaRepositoryProvider.of(context).openIssueURL(context, credentialType.fullId);
                    },
                  );
                },
              )
            ],
          ),
          GoRoute(
            path: 'debug',
            builder: (context, state) => const DebugScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => SettingsScreen(),
            routes: [
              GoRoute(
                path: 'change_language',
                builder: (context, state) => ChangeLanguageScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => NotificationsTab(),
          ),
        ],
      ),
      GoRoute(
        path: '/session',
        builder: (context, state) {
          final args = SessionRouteParams.fromQueryParams(state.uri.queryParameters);
          return SessionScreen(arguments: args);
        },
      ),
      GoRoute(
        path: '/unknown_session',
        builder: (context, state) {
          final args = SessionRouteParams.fromQueryParams(state.uri.queryParameters);
          return UnknownSessionScreen(arguments: args);
        },
      ),
      GoRoute(
        path: '/issue_wizard',
        builder: (context, state) {
          final args = IssueWizardRouteParams.fromQueryParams(state.uri.queryParameters);
          return IssueWizardScreen(arguments: args);
        },
      ),
      GoRoute(
        path: '/issue_wizard_success',
        builder: (context, state) {
          final (successHeader, successContent) = state.extra as (TranslatedValue?, TranslatedValue?);
          return IssueWizardSuccessScreen(
            onDismiss: context.goHomeScreenWithoutTransition,
            args: IssueWizardSuccessScreenArgs(headerTranslation: successHeader, contentTranslation: successContent),
          );
        },
      ),
      GoRoute(
        path: '/rooted_warning',
        builder: (context, state) {
          return RootedWarningScreen(
            onAcceptRiskButtonPressed: () {
              DetectRootedDeviceIrmaPrefsRepository(preferences: repo.preferences).setHasAcceptedRootedDeviceRisk();
            },
          );
        },
      ),
      GoRoute(
        path: '/name_changed',
        builder: (context, state) {
          return NameChangedScreen(onContinuePressed: () => repo.preferences.setShowNameChangedNotification(false));
        },
      ),
      GoRoute(
        path: '/update_required',
        builder: (context, state) => RequiredUpdateScreen(),
      ),
      GoRoute(
        path: '/mzr_reader',
        builder: (context, state) {
          return MzrReaderScreen(
            onSuccess: (mrzResult) => context.pushNfcReadingScreen(NfcReadingRouteParams(
              docNumber: mrzResult.documentNumber,
              dateOfBirth: mrzResult.birthDate,
              dateOfExpiry: mrzResult.expiryDate,
              countryCode: mrzResult.countryCode,
            )),
            onManualAdd: () => context.pushPassportManualEnterScreen(),
            onCancel: () => context.pop(),
          );
        },
      ),
      GoRoute(
          path: '/passport_manual_enter',
          builder: (context, state) => ManualEntryScreen(
                onCancel: () => context.pop(),
                onContinue: (data) => context.pushNfcReadingScreen(NfcReadingRouteParams(
                  docNumber: data.documentNr,
                  dateOfBirth: data.dateOfBirth,
                  dateOfExpiry: data.expiryDate,
                )),
              )),
      GoRoute(
        path: '/nfc_reading',
        builder: (context, state) {
          final args = NfcReadingRouteParams.fromQueryParams(state.uri.queryParameters);
          return NfcReadingScreen(
            docNumber: args.docNumber,
            dateOfBirth: args.dateOfBirth,
            dateOfExpiry: args.dateOfExpiry,
            countryCode: args.countryCode,
            onCancel: () => context.goHomeScreen(),
          );
        },
      ),
    ],
    redirect: (context, state) {
      if (redirectionTriggers.value.enrollmentStatus == EnrollmentStatus.unenrolled) {
        return '/enrollment';
      }
      if (redirectionTriggers.value.showDeviceRootedWarning) {
        return '/rooted_warning';
      }
      if (redirectionTriggers.value.showNameChangedMessage) {
        return '/name_changed';
      }
      if (redirectionTriggers.value.versionInformation != null &&
          redirectionTriggers.value.versionInformation!.updateRequired()) {
        return '/update_required';
      }
      if (redirectionTriggers.value.appLocked && !whiteListedOnLocked.contains(state.fullPath)) {
        return '/pin';
      }
      return null;
    },
  );
}

class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      throw Exception(
        'Route not found. Invalid route or invalid arguments were specified.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Page not found'),
      ),
      body: const Center(
        child: Text(''),
      ),
    );
  }
}

class RedirectionListenable extends ValueNotifier<RedirectionTriggers> {
  late final Stream<RedirectionTriggers> _streamSubscription;

  RedirectionListenable(IrmaRepository repo) : super(RedirectionTriggers.withDefaults()) {
    final warningStream = _displayDeviceIsRootedWarning(repo);
    final lockedStream = repo.getLocked();
    final infoStream = repo.getVersionInformation().map<VersionInformation?>((version) => version).defaultIfEmpty(null);
    final nameChangedStream = repo.preferences.getShowNameChangedNotification();
    final enrollmentStream = repo.getEnrollmentStatus();

    // combine the streams into one
    _streamSubscription = Rx.combineLatest5(
      warningStream,
      lockedStream,
      infoStream,
      nameChangedStream,
      enrollmentStream,
      (deviceRootedWarning, locked, versionInfo, nameChangedWarning, enrollment) {
        return RedirectionTriggers(
          appLocked: locked,
          showDeviceRootedWarning: deviceRootedWarning,
          showNameChangedMessage: nameChangedWarning,
          versionInformation: versionInfo,
          enrollmentStatus: enrollment,
        );
      },
    );

    // listen for updates from the streams
    _streamSubscription.listen((triggers) {
      if (value != triggers) {
        value = triggers;
      }
    });
  }
}

class RedirectionTriggers {
  final bool appLocked;
  final bool showDeviceRootedWarning;
  final bool showNameChangedMessage;
  final VersionInformation? versionInformation;
  final EnrollmentStatus enrollmentStatus;

  RedirectionTriggers({
    required this.appLocked,
    required this.showDeviceRootedWarning,
    required this.showNameChangedMessage,
    required this.versionInformation,
    required this.enrollmentStatus,
  });

  RedirectionTriggers.withDefaults()
      : enrollmentStatus = EnrollmentStatus.undetermined,
        appLocked = true,
        showDeviceRootedWarning = false,
        showNameChangedMessage = false,
        versionInformation = null;

  RedirectionTriggers copyWith({
    bool? appLocked,
    bool? showDeviceRootedWarning,
    bool? showNameChangedMessage,
    VersionInformation? versionInformation,
    EnrollmentStatus? enrollmentStatus,
  }) {
    return RedirectionTriggers(
      appLocked: appLocked ?? this.appLocked,
      showDeviceRootedWarning: showDeviceRootedWarning ?? this.showDeviceRootedWarning,
      showNameChangedMessage: showNameChangedMessage ?? this.showNameChangedMessage,
      versionInformation: versionInformation ?? this.versionInformation,
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is RedirectionTriggers &&
        appLocked == other.appLocked &&
        showDeviceRootedWarning == other.showDeviceRootedWarning &&
        showNameChangedMessage == other.showNameChangedMessage &&
        versionInformation == other.versionInformation &&
        enrollmentStatus == other.enrollmentStatus;
  }

  @override
  String toString() {
    return 'lock: $appLocked, enroll: $enrollmentStatus, rooted: $showDeviceRootedWarning, name: $showNameChangedMessage, version: $versionInformation';
  }

  @override
  int get hashCode => Object.hash(
        appLocked,
        showNameChangedMessage,
        showDeviceRootedWarning,
        versionInformation,
        enrollmentStatus,
      );
}

Stream<bool> _displayDeviceIsRootedWarning(IrmaRepository irmaRepo) {
  final repo = DetectRootedDeviceIrmaPrefsRepository(preferences: irmaRepo.preferences);
  final streamController = StreamController<bool>();
  repo.isDeviceRooted().then((isRooted) {
    if (isRooted) {
      repo.hasAcceptedRootedDeviceRisk().map((acceptedRisk) => !acceptedRisk).pipe(streamController);
    } else {
      streamController.add(false);
    }
  });
  return streamController.stream;
}
