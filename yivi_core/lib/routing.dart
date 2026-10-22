import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:rxdart/rxdart.dart";
import "package:vcmrtd/vcmrtd.dart" show DocumentType;

import "src/data/irma_repository.dart";
import "src/models/enrollment_status.dart";
import "src/models/log_entry.dart";
import "src/models/mrz.dart";
import "src/models/translated_value.dart";
import "src/models/version_information.dart";
import "src/providers/email_issuance_provider.dart";
import "src/providers/irma_repository_provider.dart";
import "src/providers/ocr_processor_provider.dart";
import "src/providers/pane_selection_provider.dart";
import "src/providers/rooted_device_detector_provider.dart";
import "src/screens/activity/activity_detail_screen.dart";
import "src/screens/back_to_website/back_to_website_screen.dart";
import "src/screens/change_language/change_language_screen.dart";
import "src/screens/change_pin/change_pin_screen.dart";
import "src/screens/data/credential_detail/credential_detail_screen.dart";
import "src/screens/data/schemaless_credentials_details_screen.dart";
import "src/screens/data/wallet/wallet_transition.dart";
import "src/screens/debug/debug_screen.dart";
import "src/screens/debug/feature_flags_screen.dart";
import "src/screens/embedded_issuance_flows/documents/document_flow_steps.dart";
import "src/screens/embedded_issuance_flows/email/email_issuance_screen.dart";
import "src/screens/embedded_issuance_flows/sms/sms_issuance_screen.dart";
import "src/screens/enrollment/enrollment_screen.dart";
import "src/screens/error/error_screen.dart";
import "src/screens/help/help_screen.dart";
import "src/screens/home/home_screen.dart";
import "src/screens/home/pane_handoffs.dart";
import "src/screens/issue_wizard/issue_wizard.dart";
import "src/screens/issue_wizard/widgets/issue_wizard_success_screen.dart";
import "src/screens/loading/loading_screen.dart";
import "src/screens/name_changed/name_changed_screen.dart";
import "src/screens/notifications/notifications_tab.dart";
import "src/screens/pin/pin_screen.dart";
import "src/screens/required_update/required_update_screen.dart";
import "src/screens/reset_pin/reset_pin_screen.dart";
import "src/screens/rooted_warning/repository.dart";
import "src/screens/rooted_warning/rooted_device_detector.dart";
import "src/screens/rooted_warning/rooted_warning_screen.dart";
import "src/screens/session/session_screen.dart";
import "src/screens/session/unknown_session_screen.dart";
import "src/screens/settings/settings_screen.dart";
import "src/util/navigation.dart";
import "src/widgets/adaptive_page.dart";
import "src/widgets/irma_app_bar.dart";

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

/// A route whose screen is presented by [mode] on tablets and comes in with
/// [phone] on phones (see [AdaptivePage]).
GoRoute _adaptive({
  required PresentationMode mode,
  PhoneTransition phone = PhoneTransition.push,
  required String path,
  required GoRouterWidgetBuilder builder,
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  routes: routes,
  pageBuilder: (context, state) => AdaptivePage<void>(
    key: state.pageKey,
    name: state.uri.path,
    mode: mode,
    phoneTransition: phone,
    child: builder(context, state),
  ),
);

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(BuildContext buildContext, WidgetRef ref) {
  final repo = IrmaRepositoryProvider.of(buildContext);
  final rootedDeviceDetector = ref.read(rootedDeviceDetectorProvider);
  final redirectionTriggers = RedirectionListenable(repo, rootedDeviceDetector);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: [routeObserver],
    initialLocation: "/loading",
    refreshListenable: redirectionTriggers,
    errorBuilder: (context, state) => RouteNotFoundScreen(),
    routes: [
      _adaptive(
        mode: PresentationMode.sheet,
        phone: PhoneTransition.push,
        path: "/error",
        builder: (context, state) => ErrorScreen(
          details: state.extra as String,
          onTapClose: context.pop,
        ),
      ),
      GoRoute(
        path: "/loading",
        pageBuilder: (context, state) =>
            NoTransitionPage(name: "/loading", child: LoadingScreen()),
      ),
      _adaptive(
        mode: PresentationMode.full,
        phone: PhoneTransition.fade,
        path: "/modal_pin",
        builder: (context, state) {
          return PinScreen(
            onAuthenticated: () => context.pop(true),
            leading: YiviBackButton(onTap: () => context.pop(false)),
          );
        },
      ),
      _adaptive(
        mode: PresentationMode.full,
        phone: PhoneTransition.push,
        path: "/reset_pin",
        builder: (context, state) => ResetPinScreen(),
      ),
      // FIXME: this cannot be a sub route of /home/settings, because it uses its own navigator internally
      _adaptive(
        mode: PresentationMode.sheet,
        phone: PhoneTransition.push,
        path: "/change_pin",
        builder: (context, state) => ChangePinScreen(),
      ),
      // The enrollment lays itself out for every size (two columns when the
      // window is wider than high), so it gets the whole window.
      _adaptive(
        mode: PresentationMode.window,
        phone: PhoneTransition.push,
        path: "/enrollment",
        builder: (context, state) => EnrollmentScreen(),
      ),
      _adaptive(
        mode: PresentationMode.sheet,
        phone: PhoneTransition.push,
        path: "/back_to_website",
        builder: (context, state) => const BackToWebsiteScreen(),
      ),
      GoRoute(
        path: "/home",
        pageBuilder: (context, state) {
          if (TransitionStyleProvider.shouldPerformInstantTransitionToHome(
            context,
          )) {
            TransitionStyleProvider.resetInstantTransitionToHomeMark(context);
            return NoTransitionPage(name: "/home", child: HomeScreen());
          }
          return MaterialPage(name: "/home", child: HomeScreen());
        },
        routes: [
          GoRoute(
            path: "credential",
            // Moves the data tab's items out of the way while the card
            // flies (see WalletTransition).
            pageBuilder: (context, state) => WalletDetailPage(
              key: state.pageKey,
              name: "/home/credential",
              // Turned sideways, the card moves into the tab's detail pane.
              child: cardHandoff(
                context,
                state.uri.queryParameters["hash"] ?? "",
                CredentialDetailScreen(
                  hash: state.uri.queryParameters["hash"] ?? "",
                ),
              ),
            ),
          ),
          _adaptive(
            mode: PresentationMode.sheet,
            phone: PhoneTransition.push,
            path: "credentials_details",
            builder: (context, state) {
              final args = CredentialsDetailsRouteParams.fromQueryParams(
                state.uri.queryParameters,
              );
              return SchemalessCredentialsDetailsScreen(
                credentialTypeId: args.credentialTypeId,
              );
            },
          ),
          GoRoute(
            path: "activity_details",
            // The cards of the row fly into the details while the activity
            // list moves away (see WalletTransition). On tablets the details
            // show in the pane instead.
            pageBuilder: (context, state) => WalletDetailPage(
              key: state.pageKey,
              name: "/home/activity_details",
              child: activityHandoff(
                context,
                state.extra as LogInfo,
                ActivityDetailsScreen(
                  args: ActivityDetailsScreenArgs(
                    logEntry: state.extra as LogInfo,
                  ),
                ),
              ),
            ),
          ),
          _adaptive(
            mode: PresentationMode.sheet,
            path: "help",
            builder: (context, state) =>
                morePageHandoff(context, MorePage.faq, const HelpScreen()),
          ),
          _adaptive(
            mode: PresentationMode.sheet,
            phone: PhoneTransition.push,
            path: "debug",
            builder: (context, state) => const DebugScreen(),
            routes: [
              _adaptive(
                mode: PresentationMode.sheet,
                phone: PhoneTransition.push,
                path: "feature_flags",
                builder: (context, state) => const FeatureFlagsScreen(),
              ),
            ],
          ),
          _adaptive(
            mode: PresentationMode.sheet,
            phone: PhoneTransition.push,
            path: "settings",
            builder: (context, state) => morePageHandoff(
              context,
              MorePage.settings,
              const SettingsScreen(),
            ),
            routes: [
              _adaptive(
                mode: PresentationMode.sheet,
                phone: PhoneTransition.push,
                path: "change_language",
                builder: (context, state) => ChangeLanguageScreen(),
              ),
            ],
          ),
          GoRoute(
            path: "notifications",
            builder: (context, state) => NotificationsTab(),
          ),
        ],
      ),
      _adaptive(
        mode: PresentationMode.window,
        phone: PhoneTransition.rise,
        path: "/session",
        builder: (context, state) {
          final args = SessionRouteParams.fromQueryParams(
            state.uri.queryParameters,
          );
          return SessionScreen(
            sessionId: args.sessionId,
            hasUnderlyingSession: args.hasUnderlyingSession,
          );
        },
      ),
      _adaptive(
        mode: PresentationMode.sheet,
        phone: PhoneTransition.push,
        path: "/unknown_session",
        builder: (context, state) {
          final args = SessionRouteParams.fromQueryParams(
            state.uri.queryParameters,
          );
          return UnknownSessionScreen(arguments: args);
        },
      ),
      GoRoute(
        path: "/issue_wizard",
        builder: (context, state) {
          final args = IssueWizardRouteParams.fromQueryParams(
            state.uri.queryParameters,
          );
          return IssueWizardScreen(arguments: args);
        },
      ),
      GoRoute(
        path: "/issue_wizard_success",
        builder: (context, state) {
          final (successHeader, successContent) =
              state.extra as (TranslatedValue?, TranslatedValue?);
          return IssueWizardSuccessScreen(
            onDismiss: context.goHomeScreenWithoutTransition,
            args: IssueWizardSuccessScreenArgs(
              headerTranslation: successHeader,
              contentTranslation: successContent,
            ),
          );
        },
      ),
      _adaptive(
        mode: PresentationMode.full,
        phone: PhoneTransition.push,
        path: "/rooted_warning",
        builder: (context, state) {
          return RootedWarningScreen(
            onAcceptRiskButtonPressed: () {
              DetectRootedDeviceIrmaPrefsRepository(
                preferences: repo.preferences,
                detector: rootedDeviceDetector,
              ).setHasAcceptedRootedDeviceRisk();
            },
          );
        },
      ),
      _adaptive(
        mode: PresentationMode.full,
        phone: PhoneTransition.push,
        path: "/name_changed",
        builder: (context, state) {
          return NameChangedScreen(
            onContinuePressed: () =>
                repo.preferences.setShowNameChangedNotification(false),
          );
        },
      ),
      _adaptive(
        mode: PresentationMode.full,
        phone: PhoneTransition.push,
        path: "/update_required",
        builder: (context, state) => RequiredUpdateScreen(),
      ),
      _adaptive(
        mode: PresentationMode.sheet,
        phone: PhoneTransition.rise,
        path: "/issue_mobilenumber",
        builder: (context, state) => SmsIssuanceScreen(),
      ),
      _adaptive(
        mode: PresentationMode.sheet,
        phone: PhoneTransition.rise,
        path: "/issue_email",
        builder: (context, state) => EmailIssuanceScreen(
          purpose:
              state.extra as EmailIssuancePurpose? ??
              EmailIssuancePurpose.addCredential,
        ),
      ),
      GoRoute(
        path: "/mrz",
        builder: (context, state) => Container(),
        routes: [
          _adaptive(
            mode: PresentationMode.sheet,
            phone: PhoneTransition.rise,
            path: "/instructions/:type",
            builder: (context, state) {
              final documentType = DocumentType.values.byName(
                state.pathParameters["type"]!,
              );
              return DocumentFlowSteps.instruction(
                documentType,
                onCancel: context.pop,
                onStart: () => context.pushDocumentCapture(
                  documentType,
                  ocrProcessor: ref.read(ocrProcessorProvider),
                ),
              );
            },
          ),
          GoRoute(
            path: "/manual_entry",
            builder: (context, state) => Container(),
            routes: [
              for (final (path, type) in _documentPaths)
                _adaptive(
                  mode: PresentationMode.sheet,
                  phone: PhoneTransition.rise,
                  path: "/$path",
                  builder: (context, state) => DocumentFlowSteps.manualEntry(
                    type,
                    onCancel: context.pop,
                    onRead: context.pushNfcReadingScreenFor,
                  ),
                ),
            ],
          ),
          GoRoute(
            path: "/reader",
            builder: (context, state) => Container(),
            routes: [
              for (final (path, type) in _documentPaths)
                _adaptive(
                  mode: PresentationMode.sheet,
                  phone: PhoneTransition.rise,
                  path: "/$path",
                  builder: (context, state) => DocumentFlowSteps.reader(
                    type,
                    onRead: context.pushNfcReadingScreenFor,
                    onManual: () => switch (type) {
                      .passport => context.pushPassportManualEntryScreen(),
                      .identityCard => context.pushIdCardManualEntryScreen(),
                      .drivingLicence =>
                        context.pushDrivingLicenceManualEntryScreen(),
                    },
                    onCancel: context.pop,
                  ),
                ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: "/nfc",
        builder: (context, state) => Container(),
        routes: [
          _adaptive(
            mode: PresentationMode.sheet,
            phone: PhoneTransition.rise,
            path: "/driving_licence",
            builder: (context, state) {
              final args = DrivingLicenceNfcReadingRouteParams.fromQueryParams(
                state.uri.queryParameters,
              );
              return DocumentFlowSteps.nfc(
                ScannedDrivingLicenceMrz(
                  documentNumber: args.documentNumber,
                  countryCode: args.countryCode,
                  version: args.version,
                  randomData: args.randomData,
                  configuration: args.configuration,
                ),
                onCancel: context.goHomeScreen,
              );
            },
          ),
          for (final (path, type) in _documentPaths)
            if (type != .drivingLicence)
              _adaptive(
                mode: PresentationMode.sheet,
                phone: PhoneTransition.rise,
                path: "/$path",
                builder: (context, state) {
                  final args = PassportNfcReadingRouteParams.fromQueryParams(
                    state.uri.queryParameters,
                  );
                  return DocumentFlowSteps.nfc(
                    type == .passport
                        ? ScannedPassportMrz(
                            documentNumber: args.documentNumber,
                            countryCode: args.countryCode ?? "",
                            dateOfBirth: args.dateOfBirth,
                            dateOfExpiry: args.dateOfExpiry,
                          )
                        : ScannedIdCardMrz(
                            documentNumber: args.documentNumber,
                            countryCode: args.countryCode ?? "",
                            dateOfBirth: args.dateOfBirth,
                            dateOfExpiry: args.dateOfExpiry,
                          ),
                    onCancel: context.goHomeScreen,
                  );
                },
              ),
        ],
      ),
    ],
    redirect: (context, state) {
      if (redirectionTriggers.value.showDeviceRootedWarning) {
        return "/rooted_warning";
      }
      if (redirectionTriggers.value.enrollmentStatus == .unenrolled) {
        return "/enrollment";
      }
      if (redirectionTriggers.value.showNameChangedMessage) {
        return "/name_changed";
      }
      if (redirectionTriggers.value.versionInformation != null &&
          redirectionTriggers.value.versionInformation!.updateRequired()) {
        return "/update_required";
      }
      return null;
    },
  );
}

/// The route path of each document's MRZ and NFC screens.
const _documentPaths = [
  ("passport", DocumentType.passport),
  ("id_card", DocumentType.identityCard),
  ("driving_licence", DocumentType.drivingLicence),
];

class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      throw Exception(
        "Route not found. Invalid route or invalid arguments were specified.",
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Page not found")),
      body: const Center(child: Text("")),
    );
  }
}

class RedirectionListenable extends ValueNotifier<RedirectionTriggers> {
  late final Stream<RedirectionTriggers> _streamSubscription;

  RedirectionListenable(IrmaRepository repo, RootedDeviceDetector detector)
    : super(RedirectionTriggers.withDefaults()) {
    final warningStream = _displayDeviceIsRootedWarning(repo, detector);
    final infoStream = repo
        .getVersionInformation()
        .map<VersionInformation?>((version) => version)
        .defaultIfEmpty(null);
    final nameChangedStream = repo.preferences.getShowNameChangedNotification();
    final enrollmentStream = repo.getEnrollmentStatus();

    // combine the streams into one
    _streamSubscription = Rx.combineLatest4(
      warningStream,
      infoStream,
      nameChangedStream,
      enrollmentStream,
      (deviceRootedWarning, versionInfo, nameChangedWarning, enrollment) {
        return RedirectionTriggers(
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
  final bool showDeviceRootedWarning;
  final bool showNameChangedMessage;
  final VersionInformation? versionInformation;
  final EnrollmentStatus enrollmentStatus;

  RedirectionTriggers({
    required this.showDeviceRootedWarning,
    required this.showNameChangedMessage,
    required this.versionInformation,
    required this.enrollmentStatus,
  });

  RedirectionTriggers.withDefaults()
    : enrollmentStatus = .undetermined,
      showDeviceRootedWarning = false,
      showNameChangedMessage = false,
      versionInformation = null;

  RedirectionTriggers copyWith({
    bool? showDeviceRootedWarning,
    bool? showNameChangedMessage,
    VersionInformation? versionInformation,
    EnrollmentStatus? enrollmentStatus,
  }) {
    return RedirectionTriggers(
      showDeviceRootedWarning:
          showDeviceRootedWarning ?? this.showDeviceRootedWarning,
      showNameChangedMessage:
          showNameChangedMessage ?? this.showNameChangedMessage,
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
        showDeviceRootedWarning == other.showDeviceRootedWarning &&
        showNameChangedMessage == other.showNameChangedMessage &&
        versionInformation == other.versionInformation &&
        enrollmentStatus == other.enrollmentStatus;
  }

  @override
  String toString() {
    return "enroll: $enrollmentStatus, rooted: $showDeviceRootedWarning, name: $showNameChangedMessage, version: $versionInformation";
  }

  @override
  int get hashCode => Object.hash(
    showNameChangedMessage,
    showDeviceRootedWarning,
    versionInformation,
    enrollmentStatus,
  );
}

Stream<bool> _displayDeviceIsRootedWarning(
  IrmaRepository irmaRepo,
  RootedDeviceDetector detector,
) {
  final repo = DetectRootedDeviceIrmaPrefsRepository(
    preferences: irmaRepo.preferences,
    detector: detector,
  );
  final streamController = StreamController<bool>();
  repo.isDeviceRooted().then((isRooted) {
    if (isRooted) {
      repo
          .hasAcceptedRootedDeviceRisk()
          .map((acceptedRisk) => !acceptedRisk)
          .pipe(streamController);
    } else {
      streamController.add(false);
    }
  });
  return streamController.stream;
}
