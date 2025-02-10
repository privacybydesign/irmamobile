import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';

import 'src/data/irma_repository.dart';
import 'src/models/enrollment_status.dart';
import 'src/models/irma_configuration.dart';
import 'src/models/log_entry.dart';
import 'src/models/version_information.dart';
import 'src/screens/activity/activity_detail_screen.dart';
import 'src/screens/add_data/add_data_details_screen.dart';
import 'src/screens/add_data/add_data_screen.dart';
import 'src/screens/change_language/change_language_screen.dart';
import 'src/screens/change_pin/change_pin_screen.dart';
import 'src/screens/data/credentials_detail_screen.dart';
import 'src/screens/debug/debug_screen.dart';
import 'src/screens/enrollment/enrollment_screen.dart';
import 'src/screens/error/error_screen.dart';
import 'src/screens/help/help_screen.dart';
import 'src/screens/home/home_screen.dart';
import 'src/screens/issue_wizard/issue_wizard.dart';
import 'src/screens/loading/loading_screen.dart';
import 'src/screens/name_changed/name_changed_screen.dart';
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

GoRouter createRouter(BuildContext buildContext) {
  final repo = IrmaRepositoryProvider.of(buildContext);
  final redirectionTriggers = RedirectionListenable(repo);

  final whiteListedOnLocked = {ResetPinScreen.routeName, LoadingScreen.routeName, EnrollmentScreen.routeName};

  return GoRouter(
    initialLocation: LoadingScreen.routeName,
    refreshListenable: redirectionTriggers,
    errorBuilder: (context, state) {
      return ErrorScreen(
        details: state.error?.message ?? "Something went wrong, but we don't know what",
        onTapClose: () {
          context.pop();
        },
      );
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
        path: '/credentials_details',
        builder: (context, state) {
          final (credentialTypeId, categoryName) = state.extra as (String, String);
          return CredentialsDetailScreen(credentialTypeId: credentialTypeId, categoryName: categoryName);
        },
      ),
      GoRoute(
        path: '/activity_details',
        builder: (context, state) {
          final (logEntry, irmaConfiguration) = state.extra as (LogEntry, IrmaConfiguration);
          return ActivityDetailScreen(logEntry: logEntry, irmaConfiguration: irmaConfiguration);
        },
      ),
      GoRoute(
        path: PinScreen.routeName,
        pageBuilder: (context, state) => NoTransitionPage(child: PinScreen()),
      ),
      GoRoute(
        path: ResetPinScreen.routeName,
        builder: (context, state) => ResetPinScreen(),
      ),
      GoRoute(
        path: LoadingScreen.routeName,
        pageBuilder: (context, state) => NoTransitionPage(child: LoadingScreen()),
      ),
      GoRoute(
        path: EnrollmentScreen.routeName,
        builder: (context, state) => EnrollmentScreen(),
      ),
      GoRoute(
        path: ScannerScreen.routeName,
        builder: (context, state) => ScannerScreen(),
      ),
      GoRoute(
        path: ChangePinScreen.routeName,
        builder: (context, state) => ChangePinScreen(),
      ),
      GoRoute(
        path: ChangeLanguageScreen.routeName,
        builder: (context, state) => ChangeLanguageScreen(),
      ),
      GoRoute(
        path: SettingsScreen.routeName,
        builder: (context, state) => SettingsScreen(),
      ),
      GoRoute(
        path: AddDataScreen.routeName,
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
        path: HelpScreen.routeName,
        builder: (context, state) => HelpScreen(),
      ),
      GoRoute(
        path: ResetPinScreen.routeName,
        builder: (context, state) => ResetPinScreen(),
      ),
      GoRoute(
        path: DebugScreen.routeName,
        builder: (context, state) => const DebugScreen(),
      ),
      GoRoute(
        path: HomeScreen.routeName,
        pageBuilder: (context, state) => NoTransitionPage(child: HomeScreen()),
      ),
      GoRoute(
        path: SettingsScreen.routeName,
        builder: (context, state) => SettingsScreen(),
      ),
      GoRoute(
        path: SessionScreen.routeName,
        builder: (context, state) => SessionScreen(arguments: state.extra as SessionScreenArguments),
      ),
      GoRoute(
        path: UnknownSessionScreen.routeName,
        builder: (context, state) => UnknownSessionScreen(arguments: state.extra as SessionScreenArguments),
      ),
      GoRoute(
        path: IssueWizardScreen.routeName,
        builder: (context, state) => IssueWizardScreen(arguments: state.extra as IssueWizardScreenArguments),
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
      print('trying to go to ${state.fullPath}');
      if (redirectionTriggers.value.enrollmentStatus == EnrollmentStatus.unenrolled) {
        print('redirect to /enrollment');
        return '/enrollment';
      }
      if (redirectionTriggers.value.showDeviceRootedWarning) {
        print('redirect to /rooted_warning');
        return '/rooted_warning';
      }
      if (redirectionTriggers.value.showNameChangedMessage) {
        print('redirect to /name_changed');
        return '/name_changed';
      }
      if (redirectionTriggers.value.versionInformation != null &&
          redirectionTriggers.value.versionInformation!.updateRequired()) {
        print('redirect to /update_required');
        return '/update_required';
      }
      if (redirectionTriggers.value.appLocked && !whiteListedOnLocked.contains(state.fullPath)) {
        print('redirect to /pin');
        return PinScreen.routeName;
      }
      print('go to path ${state.fullPath}');
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
