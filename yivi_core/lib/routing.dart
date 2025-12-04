import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:rxdart/rxdart.dart";

import "src/data/irma_repository.dart";
import "src/models/enrollment_status.dart";
import "src/models/irma_configuration.dart";
import "src/models/log_entry.dart";
import "src/models/mrz.dart";
import "src/models/translated_value.dart";
import "src/models/version_information.dart";
import "src/providers/irma_repository_provider.dart";
import "src/screens/activity/activity_detail_screen.dart";
import "src/screens/add_data/add_data_details_screen.dart";
import "src/screens/add_data/add_data_screen.dart";
import "src/screens/change_language/change_language_screen.dart";
import "src/screens/change_pin/change_pin_screen.dart";
import "src/screens/data/credentials_details_screen.dart";
import "src/screens/debug/debug_screen.dart";
import "src/screens/documents/driving_licence_mrz_manual_entry_screen.dart";
import "src/screens/documents/mrz_reader_screen.dart";
import "src/screens/documents/nfc_reading_screen.dart";
import "src/screens/documents/passport_mrz_manual_entry_screen.dart";
import "src/screens/documents/widgets/driving_licence_mrz_camera_overlay.dart";
import "src/screens/documents/widgets/passport_mrz_camera_overlay.dart";
import "src/screens/enrollment/enrollment_screen.dart";
import "src/screens/error/error_screen.dart";
import "src/screens/help/help_screen.dart";
import "src/screens/home/home_screen.dart";
import "src/screens/home/widgets/irma_qr_scan_button.dart";
import "src/screens/issue_wizard/issue_wizard.dart";
import "src/screens/issue_wizard/widgets/issue_wizard_success_screen.dart";
import "src/screens/loading/loading_screen.dart";
import "src/screens/name_changed/name_changed_screen.dart";
import "src/screens/notifications/notifications_tab.dart";
import "src/screens/pin/pin_screen.dart";
import "src/screens/required_update/required_update_screen.dart";
import "src/screens/reset_pin/reset_pin_screen.dart";
import "src/screens/rooted_warning/repository.dart";
import "src/screens/rooted_warning/rooted_warning_screen.dart";
import "src/screens/scanner/scanner_screen.dart";
import "src/screens/session/session_screen.dart";
import "src/screens/session/unknown_session_screen.dart";
import "src/screens/settings/settings_screen.dart";
import "src/screens/terms_changed/terms_changed_dialog.dart";
import "src/util/navigation.dart";
import "src/widgets/irma_app_bar.dart";

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(BuildContext buildContext, WidgetRef ref) {
  final repo = IrmaRepositoryProvider.of(buildContext);
  final redirectionTriggers = RedirectionListenable(repo);

  const whiteListedOnLocked = {
    "/reset_pin",
    "/loading",
    "/enrollment",
    "/scanner",
    "/modal_pin",
  };

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: [routeObserver],
    initialLocation: "/loading",
    refreshListenable: redirectionTriggers,
    errorBuilder: (context, state) => RouteNotFoundScreen(),
    routes: [
      GoRoute(
        path: "/scanner",
        builder: (context, state) {
          final requireAuth = bool.parse(
            state.uri.queryParameters["require_auth_before_session"]!,
          );
          return ScannerScreen(requireAuthBeforeSession: requireAuth);
        },
      ),
      GoRoute(
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
      GoRoute(
        path: "/pin",
        pageBuilder: (context, state) {
          return NoTransitionPage(
            name: "/pin",
            child: Builder(
              builder: (context) {
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
              },
            ),
          );
        },
      ),
      GoRoute(
        path: "/modal_pin",
        builder: (context, state) {
          return PinScreen(
            onAuthenticated: () => context.pop(true),
            leading: YiviBackButton(onTap: () => context.pop(false)),
          );
        },
      ),
      GoRoute(
        path: "/reset_pin",
        builder: (context, state) => ResetPinScreen(),
      ),
      // FIXME: this cannot be a sub route of /home/settings, because it uses its own navigator internally
      GoRoute(
        path: "/change_pin",
        builder: (context, state) => ChangePinScreen(),
      ),
      GoRoute(
        path: "/enrollment",
        builder: (context, state) => EnrollmentScreen(),
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
            path: "credentials_details",
            builder: (context, state) {
              final args = CredentialsDetailsRouteParams.fromQueryParams(
                state.uri.queryParameters,
              );
              return CredentialsDetailsScreen(
                categoryName: args.categoryName,
                credentialTypeId: args.credentialTypeId,
              );
            },
          ),
          GoRoute(
            path: "activity_details",
            builder: (context, state) {
              final (logEntry, irmaConfiguration) =
                  state.extra as (LogInfo, IrmaConfiguration);
              return ActivityDetailsScreen(
                args: ActivityDetailsScreenArgs(
                  logEntry: logEntry,
                  irmaConfiguration: irmaConfiguration,
                ),
              );
            },
          ),
          GoRoute(path: "help", builder: (context, state) => HelpScreen()),
          GoRoute(
            path: "add_data",
            builder: (context, state) => AddDataScreen(),
            routes: [
              GoRoute(
                path: "details",
                builder: (context, state) {
                  final credentialType = state.extra as CredentialType;
                  return AddDataDetailsScreen(
                    credentialType: credentialType,
                    onCancel: context.pop,
                    onAdd: () {
                      IrmaRepositoryProvider.of(
                        context,
                      ).openIssueURL(context, credentialType, ref);
                    },
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: "debug",
            builder: (context, state) => const DebugScreen(),
          ),
          GoRoute(
            path: "settings",
            builder: (context, state) => SettingsScreen(),
            routes: [
              GoRoute(
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
      GoRoute(
        path: "/session",
        builder: (context, state) {
          final args = SessionRouteParams.fromQueryParams(
            state.uri.queryParameters,
          );
          return SessionScreen(arguments: args);
        },
      ),
      GoRoute(
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
      GoRoute(
        path: "/rooted_warning",
        builder: (context, state) {
          return RootedWarningScreen(
            onAcceptRiskButtonPressed: () {
              DetectRootedDeviceIrmaPrefsRepository(
                preferences: repo.preferences,
              ).setHasAcceptedRootedDeviceRisk();
            },
          );
        },
      ),
      GoRoute(
        path: "/name_changed",
        builder: (context, state) {
          return NameChangedScreen(
            onContinuePressed: () =>
                repo.preferences.setShowNameChangedNotification(false),
          );
        },
      ),
      GoRoute(
        path: "/update_required",
        builder: (context, state) => RequiredUpdateScreen(),
      ),
      GoRoute(
        path: "/mrz",
        builder: (context, state) => Container(),
        routes: [
          GoRoute(
            path: "/manual_entry",
            builder: (context, state) => Container(),
            routes: [
              GoRoute(
                path: "/driving_licence",
                builder: (context, state) {
                  return DrivingLicenceMrzManualEntryScreen(
                    onCancel: context.pop,
                    onContinue: (data) {
                      context.pushDrivingLicenceNfcReadingScreen(
                        DrivingLicenceNfcReadingRouteParams(
                          documentNumber: data.documentNumber,
                          version: data.version,
                          randomData: data.randomData,
                          configuration: data.configuration,
                          countryCode: data.countryCode,
                        ),
                      );
                    },
                  );
                },
              ),
              GoRoute(
                path: "/passport",
                builder: (context, state) {
                  return PassportMrzManualEntryScreen(
                    onCancel: context.pop,
                    onContinue: (data) {
                      context.pushPassportNfcReadingScreen(
                        PassportNfcReadingRouteParams(
                          documentNumber: data.documentNr,
                          dateOfBirth: data.dateOfBirth,
                          dateOfExpiry: data.expiryDate,
                        ),
                      );
                    },
                  );
                },
              ),
              GoRoute(
                path: "/id_card",
                builder: (context, state) {
                  return PassportMrzManualEntryScreen(
                    onCancel: context.pop,
                    onContinue: (data) {
                      context.pushIdCardNfcReadingScreen(
                        PassportNfcReadingRouteParams(
                          documentNumber: data.documentNr,
                          dateOfBirth: data.dateOfBirth,
                          dateOfExpiry: data.expiryDate,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: "/reader",
            builder: (context, state) => Container(),
            routes: [
              GoRoute(
                path: "/driving_licence",
                builder: (context, state) {
                  return MrzReaderScreen(
                    overlayBuilder: ({required success, required child}) =>
                        DrivingLicenceMrzCameraOverlay(
                          success: success,
                          child: child,
                        ),
                    translationKeys: MrzReaderTranslationKeys(
                      title: "driving_licence.scan.title",
                      manualEntryButton: "driving_licence.scan.manual",
                      error: "driving_licence.scan.error",
                      success: "driving_licence.scan.success",
                      successExplanation:
                          "driving_licence.scan.success_explanation",
                    ),
                    onSuccess: (mrzResult) {
                      final r = mrzResult as DrivingLicenceMrzResult;
                      context.pushDrivingLicenceNfcReadingScreen(
                        DrivingLicenceNfcReadingRouteParams(
                          documentNumber: r.documentNumber,
                          version: r.version,
                          randomData: r.randomData,
                          configuration: r.configuration,
                          countryCode: r.countryCode,
                        ),
                      );
                    },
                    onManualAdd: context.pushDrivingLicenceManualEntryScreen,
                    onCancel: context.pop,
                    mrzParser: DrivingLicenceMrzParser(),
                  );
                },
              ),
              GoRoute(
                path: "/passport",
                builder: (context, state) {
                  return MrzReaderScreen(
                    overlayBuilder: ({required success, required child}) =>
                        PassportMrzCameraOverlay(
                          success: success,
                          child: child,
                        ),
                    translationKeys: MrzReaderTranslationKeys(
                      title: "passport.scan.title",
                      manualEntryButton: "passport.scan.manual",
                      error: "passport.scan.error",
                      success: "passport.scan.success",
                      successExplanation: "passport.scan.success_explanation",
                    ),
                    onSuccess: (mrzResult) {
                      final r = mrzResult as PassportMrzResult;
                      context.pushPassportNfcReadingScreen(
                        PassportNfcReadingRouteParams(
                          documentNumber: r.documentNumber,
                          dateOfBirth: r.birthDate,
                          dateOfExpiry: r.expiryDate,
                          countryCode: r.countryCode,
                        ),
                      );
                    },
                    onManualAdd: context.pushPassportManualEntryScreen,
                    onCancel: context.pop,
                    mrzParser: PassportMrzParser(),
                  );
                },
              ),
              GoRoute(
                path: "/id_card",
                builder: (context, state) {
                  return MrzReaderScreen(
                    overlayBuilder: ({required success, required child}) =>
                        PassportMrzCameraOverlay(
                          success: success,
                          child: child,
                        ),
                    translationKeys: MrzReaderTranslationKeys(
                      title: "id_card.scan.title",
                      manualEntryButton: "id_card.scan.manual",
                      error: "id_card.scan.error",
                      success: "id_card.scan.success",
                      successExplanation: "id_card.scan.success_explanation",
                    ),
                    onSuccess: (mrzResult) {
                      final r = mrzResult as PassportMrzResult;
                      context.pushIdCardNfcReadingScreen(
                        PassportNfcReadingRouteParams(
                          documentNumber: r.documentNumber,
                          dateOfBirth: r.birthDate,
                          dateOfExpiry: r.expiryDate,
                          countryCode: r.countryCode,
                        ),
                      );
                    },
                    onManualAdd: context.pushPassportManualEntryScreen,
                    onCancel: context.pop,
                    mrzParser: PassportMrzParser(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: "/nfc",
        builder: (context, state) => Container(),
        routes: [
          GoRoute(
            path: "/driving_licence",
            builder: (context, state) {
              final args = DrivingLicenceNfcReadingRouteParams.fromQueryParams(
                state.uri.queryParameters,
              );
              return NfcReadingScreen(
                translationKeys: NfcReadingTranslationKeys(
                  cancelDialogTitle: "driving_licence.nfc.cancel_dialog.title",
                  cancelDialogExplanation:
                      "driving_licence.nfc.cancel_dialog.explanation",
                  cancelDialogDecline:
                      "driving_licence.nfc.cancel_dialog.decline",
                  cancelDialogConfirm:
                      "driving_licence.nfc.cancel_dialog.confirm",
                  error: "driving_licence.nfc.error",
                  errorGeneric: "driving_licence.nfc.error_generic",
                  title: "driving_licence.nfc.title",
                  nfcDisabled: "driving_licence.nfc.nfc_disabled",
                  nfcEnabled: "driving_licence.nfc.nfc_enabled",
                  introduction: "driving_licence.nfc.introduction",
                  startScanning: "driving_licence.nfc.start_scanning",
                  nfcDisabledExplanation:
                      "driving_licence.nfc.nfc_disabled_explanation",
                  holdNearPhotoPage: "driving_licence.nfc.hold_near_photo_page",
                  tip1: "driving_licence.nfc.tip_1",
                  tip2: "driving_licence.nfc.tip_2",
                  tip3: "driving_licence.nfc.tip_3",
                  successExplanation: "driving_licence.nfc.success_explanation",
                  cancelledByUser: "driving_licence.nfc.cancelled_by_user",
                  cancelled: "driving_licence.nfc.cancelled",
                  cancelling: "driving_licence.nfc.cancelling",
                  connecting: "driving_licence.nfc.connecting",
                  readingCardSecurity:
                      "driving_licence.nfc.reading_card_security",
                  readingDocumentData:
                      "driving_licence.nfc.reading_passport_data",
                  authenticating: "driving_licence.nfc.authenticating",
                  performingSecurityVerification:
                      "driving_licence.nfc.performing_security_verification",
                  timeoutWaitingForTag:
                      "driving_licence.nfc.timeout_waiting_for_tag",
                  tagLostTryAgain: "driving_licence.nfc.tag_lost_try_again",
                  failedToInitiateSession:
                      "driving_licence.nfc.failed_to_initiate_session",
                  success: "driving_licence.nfc.success",
                ),
                mrz: ScannedDrivingLicenceMrz(
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
          GoRoute(
            path: "/passport",
            builder: (context, state) {
              final args = PassportNfcReadingRouteParams.fromQueryParams(
                state.uri.queryParameters,
              );
              return NfcReadingScreen(
                translationKeys: NfcReadingTranslationKeys(
                  cancelDialogTitle: "passport.nfc.cancel_dialog.title",
                  cancelDialogExplanation:
                      "passport.nfc.cancel_dialog.explanation",
                  cancelDialogDecline: "passport.nfc.cancel_dialog.decline",
                  cancelDialogConfirm: "passport.nfc.cancel_dialog.confirm",
                  error: "passport.nfc.error",
                  errorGeneric: "passport.nfc.error_generic",
                  title: "passport.nfc.title",
                  nfcDisabled: "passport.nfc.nfc_disabled",
                  nfcEnabled: "passport.nfc.nfc_enabled",
                  introduction: "passport.nfc.introduction",
                  startScanning: "passport.nfc.start_scanning",
                  nfcDisabledExplanation:
                      "passport.nfc.nfc_disabled_explanation",
                  holdNearPhotoPage: "passport.nfc.hold_near_photo_page",
                  tip1: "passport.nfc.tip_1",
                  tip2: "passport.nfc.tip_2",
                  tip3: "passport.nfc.tip_3",
                  successExplanation: "passport.nfc.success_explanation",
                  cancelledByUser: "passport.nfc.cancelled_by_user",
                  cancelled: "passport.nfc.cancelled",
                  cancelling: "passport.nfc.cancelling",
                  connecting: "passport.nfc.connecting",
                  readingCardSecurity: "passport.nfc.reading_card_security",
                  readingDocumentData: "passport.nfc.reading_passport_data",
                  authenticating: "passport.nfc.authenticating",
                  performingSecurityVerification:
                      "passport.nfc.performing_security_verification",
                  timeoutWaitingForTag: "passport.nfc.timeout_waiting_for_tag",
                  tagLostTryAgain: "passport.nfc.tag_lost_try_again",
                  failedToInitiateSession:
                      "passport.nfc.failed_to_initiate_session",
                  success: "passport.nfc.success",
                ),
                mrz: ScannedPassportMrz(
                  documentNumber: args.documentNumber,
                  countryCode: args.countryCode ?? "",
                  dateOfBirth: args.dateOfBirth,
                  dateOfExpiry: args.dateOfExpiry,
                ),
                onCancel: context.goHomeScreen,
              );
            },
          ),
          GoRoute(
            path: "/id_card",
            builder: (context, state) {
              final args = PassportNfcReadingRouteParams.fromQueryParams(
                state.uri.queryParameters,
              );
              return NfcReadingScreen(
                translationKeys: NfcReadingTranslationKeys(
                  cancelDialogTitle: "id_card.nfc.cancel_dialog.title",
                  cancelDialogExplanation:
                      "id_card.nfc.cancel_dialog.explanation",
                  cancelDialogDecline: "id_card.nfc.cancel_dialog.decline",
                  cancelDialogConfirm: "id_card.nfc.cancel_dialog.confirm",
                  error: "id_card.nfc.error",
                  errorGeneric: "id_card.nfc.error_generic",
                  title: "id_card.nfc.title",
                  nfcDisabled: "id_card.nfc.nfc_disabled",
                  nfcEnabled: "id_card.nfc.nfc_enabled",
                  introduction: "id_card.nfc.introduction",
                  startScanning: "id_card.nfc.start_scanning",
                  nfcDisabledExplanation:
                      "id_card.nfc.nfc_disabled_explanation",
                  holdNearPhotoPage: "id_card.nfc.hold_near_photo_page",
                  tip1: "id_card.nfc.tip_1",
                  tip2: "id_card.nfc.tip_2",
                  tip3: "id_card.nfc.tip_3",
                  successExplanation: "id_card.nfc.success_explanation",
                  cancelledByUser: "id_card.nfc.cancelled_by_user",
                  cancelled: "id_card.nfc.cancelled",
                  cancelling: "id_card.nfc.cancelling",
                  connecting: "id_card.nfc.connecting",
                  readingCardSecurity: "id_card.nfc.reading_card_security",
                  readingDocumentData: "id_card.nfc.reading_passport_data",
                  authenticating: "id_card.nfc.authenticating",
                  performingSecurityVerification:
                      "id_card.nfc.performing_security_verification",
                  timeoutWaitingForTag: "id_card.nfc.timeout_waiting_for_tag",
                  tagLostTryAgain: "id_card.nfc.tag_lost_try_again",
                  failedToInitiateSession:
                      "id_card.nfc.failed_to_initiate_session",
                  success: "id_card.nfc.success",
                ),
                mrz: ScannedIdCardMrz(
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
      if (redirectionTriggers.value.enrollmentStatus == .unenrolled) {
        return "/enrollment";
      }
      if (redirectionTriggers.value.showDeviceRootedWarning) {
        return "/rooted_warning";
      }
      if (redirectionTriggers.value.showNameChangedMessage) {
        return "/name_changed";
      }
      if (redirectionTriggers.value.versionInformation != null &&
          redirectionTriggers.value.versionInformation!.updateRequired()) {
        return "/update_required";
      }
      if (redirectionTriggers.value.appLocked &&
          !whiteListedOnLocked.contains(state.fullPath)) {
        return "/pin";
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

  RedirectionListenable(IrmaRepository repo)
    : super(RedirectionTriggers.withDefaults()) {
    final warningStream = _displayDeviceIsRootedWarning(repo);
    final lockedStream = repo.getLocked();
    final infoStream = repo
        .getVersionInformation()
        .map<VersionInformation?>((version) => version)
        .defaultIfEmpty(null);
    final nameChangedStream = repo.preferences.getShowNameChangedNotification();
    final enrollmentStream = repo.getEnrollmentStatus();

    // combine the streams into one
    _streamSubscription = Rx.combineLatest5(
      warningStream,
      lockedStream,
      infoStream,
      nameChangedStream,
      enrollmentStream,
      (
        deviceRootedWarning,
        locked,
        versionInfo,
        nameChangedWarning,
        enrollment,
      ) {
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
    : enrollmentStatus = .undetermined,
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
        appLocked == other.appLocked &&
        showDeviceRootedWarning == other.showDeviceRootedWarning &&
        showNameChangedMessage == other.showNameChangedMessage &&
        versionInformation == other.versionInformation &&
        enrollmentStatus == other.enrollmentStatus;
  }

  @override
  String toString() {
    return "lock: $appLocked, enroll: $enrollmentStatus, rooted: $showDeviceRootedWarning, name: $showNameChangedMessage, version: $versionInformation";
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
  final repo = DetectRootedDeviceIrmaPrefsRepository(
    preferences: irmaRepo.preferences,
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
