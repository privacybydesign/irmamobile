import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';

import 'src/data/irma_repository.dart';
import 'src/models/enrollment_status.dart';
import 'src/models/irma_configuration.dart';
import 'src/models/version_information.dart';
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
import 'src/screens/notifications/notifications_screen.dart';
import 'src/screens/pin/pin_screen.dart';
import 'src/screens/required_update/required_update_screen.dart';
import 'src/screens/reset_pin/reset_pin_screen.dart';
import 'src/screens/rooted_warning/repository.dart';
import 'src/screens/rooted_warning/rooted_warning_screen.dart';
import 'src/screens/scanner/scanner_screen.dart';
import 'src/screens/session/session.dart';
import 'src/screens/session/session_screen.dart';
import 'src/screens/session/unknown_session_screen.dart';
import 'src/screens/settings/settings_screen.dart';
import 'src/util/navigation.dart';
import 'src/widgets/irma_app_bar.dart';
import 'src/widgets/irma_icon_button.dart';
import 'src/widgets/irma_repository_provider.dart';

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
      value = triggers;
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
  String toString() {
    return 'lock: $appLocked, enroll: $enrollmentStatus, rooted: $showDeviceRootedWarning, name: $showNameChangedMessage, version: $versionInformation';
  }
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

/// The transition to the home page should be instant in some cases and
/// "normal" in other cases. For example coming from the pin screen should be an instant transition,
/// while coming back from the add_data page should be a native sliding transition.
/// This is a hard problem, as during page building in GoRouter there is no way to detect whether
/// you're coming from a subpage or not. Passing parameters together with the context.go() call also doesn't
/// work as it remembers the parameters passed to the initial transition, so coming back from a subpage still has the
/// parameters from coming from the pin screen.
/// The (kind of hacky, ugly) solution we made up for this is to set a flag when going to the home screen
/// and resetting it when the home screen is built. This way we only have the instant transition once and
/// normal transitions for all subsequent navigation actions.
class HomeTransitionStyleProvider extends StatefulWidget {
  final Widget child;

  const HomeTransitionStyleProvider({required this.child});

  static void performInstantTransitionToHome(BuildContext context) {
    var state = context.findAncestorStateOfType<HomeTransitionStyleProviderState>();
    state!._shouldPerformInstantTransitionToHome = true;
    context.go('/home');
  }

  static bool shouldPerformInstantTransitionToHome(BuildContext context) {
    final state = context.findAncestorStateOfType<HomeTransitionStyleProviderState>();
    return state!._shouldPerformInstantTransitionToHome;
  }

  static void resetInstantTransitionToHomeMark(BuildContext context) {
    var state = context.findAncestorStateOfType<HomeTransitionStyleProviderState>();
    state!._shouldPerformInstantTransitionToHome = false;
  }

  @override
  State<StatefulWidget> createState() {
    return HomeTransitionStyleProviderState();
  }
}

class HomeTransitionStyleProviderState extends State<HomeTransitionStyleProvider> {
  bool _shouldPerformInstantTransitionToHome = false;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

GoRouter createRouter(BuildContext buildContext) {
  final repo = IrmaRepositoryProvider.of(buildContext);
  final redirectionTriggers = RedirectionListenable(repo);

  final whiteListedOnLocked = {'/reset_pin', '/loading', '/enrollment', '/scanner', '/modal_pin'};

  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: redirectionTriggers,
    errorBuilder: (context, state) {
      return RouteNotFoundScreen();
    },
    routes: [
      GoRoute(
        path: '/error',
        builder: (context, state) {
          return ErrorScreen(
            details: state.extra as String,
            onTapClose: () {
              context.pop();
            },
          );
        },
      ),
      GoRoute(
        path: '/loading',
        pageBuilder: (context, state) => NoTransitionPage(name: '/loading', child: LoadingScreen()),
      ),
      GoRoute(
        path: '/pin',
        pageBuilder: (context, state) => NoTransitionPage(
          name: '/pin',
          child: PinScreen(
            onAuthenticated: () => goToHomeWithoutTransition(context),
            leading: IrmaIconButton(
              size: 40,
              icon: CupertinoIcons.qrcode_viewfinder,
              onTap: () {
                openQrCodeScanner(context);
              },
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/modal_pin',
        builder: (context, state) => PinScreen(
          onAuthenticated: () => context.pop(true),
          leading: YiviBackButton(onTap: () => context.pop(false)),
        ),
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
        path: '/scanner',
        builder: (context, state) => ScannerScreen(),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          if (HomeTransitionStyleProvider.shouldPerformInstantTransitionToHome(context)) {
            HomeTransitionStyleProvider.resetInstantTransitionToHomeMark(context);
            return NoTransitionPage(name: '/home', child: HomeScreen());
          }
          return MaterialPage(name: '/home', child: HomeScreen());
        },
        routes: [
          GoRoute(
            path: 'credentials_details',
            builder: (context, state) {
              final args = CredentialsDetailsScreenArgs.fromQueryParams(state.uri.queryParameters);
              return CredentialsDetailsScreen(args: args);
            },
          ),
          GoRoute(
            path: 'activity_details',
            builder: (context, state) {
              final args = state.extra as ActivityDetailsScreenArgs;
              return ActivityDetailsScreen(args: args);
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
                    onCancel: () => context.pop(),
                    onAdd: () => IrmaRepositoryProvider.of(context).openIssueURL(
                      context,
                      credentialType.fullId,
                    ),
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
            builder: (context, state) => NotificationsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/session',
        builder: (context, state) {
          final args = SessionScreenArguments.fromQueryParams(state.uri.queryParameters);
          return SessionScreen(arguments: args);
        },
      ),
      GoRoute(
        path: '/unknown_session',
        builder: (context, state) {
          final args = SessionScreenArguments.fromQueryParams(state.uri.queryParameters);
          return UnknownSessionScreen(arguments: args);
        },
      ),
      GoRoute(
        path: '/issue_wizard',
        builder: (context, state) {
          final args = IssueWizardScreenArguments.fromQueryParams(state.uri.queryParameters);
          return IssueWizardScreen(arguments: args);
        },
      ),
      GoRoute(
        path: '/issue_wizard_success',
        builder: (context, state) {
          return IssueWizardSuccessScreen(
            onDismiss: () => goToHomeWithoutTransition(context),
            args: state.extra as IssueWizardSuccessScreenArgs,
          );
        },
      ),
      GoRoute(
        path: '/rooted_warning',
        builder: (context, state) {
          return RootedWarningScreen(
            onAcceptRiskButtonPressed: () async {
              DetectRootedDeviceIrmaPrefsRepository(preferences: repo.preferences).setHasAcceptedRootedDeviceRisk();
            },
          );
        },
      ),
      GoRoute(
        path: '/name_changed',
        builder: (context, state) {
          return NameChangedScreen(
            onContinuePressed: () => repo.preferences.setShowNameChangedNotification(false),
          );
        },
      ),
      GoRoute(
        path: '/update_required',
        builder: (context, state) => RequiredUpdateScreen(),
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
