import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:rxdart/rxdart.dart";

import "src/data/irma_repository.dart";
import "src/models/enrollment_status.dart";
import "src/models/log_entry.dart";
import "src/models/mrz.dart";
import "src/models/translated_value.dart";
import "src/models/version_information.dart";
import "src/providers/app_integrity_provider.dart";
import "src/providers/device_security_provider.dart";
import "src/providers/irma_repository_provider.dart";
import "src/providers/rooted_device_detector_provider.dart";
import "src/screens/activity/activity_detail_screen.dart";
import "src/screens/add_data/schemaless_add_data_details_screen.dart";
import "src/screens/add_data/schemaless_add_data_screen.dart";
import "src/screens/app_integrity/app_integrity.dart";
import "src/screens/app_integrity/app_integrity_blocked_screen.dart";
import "src/screens/change_language/change_language_screen.dart";
import "src/screens/change_pin/change_pin_screen.dart";
import "src/screens/data/schemaless_credentials_details_screen.dart";
import "src/screens/debug/debug_screen.dart";
import "src/screens/device_lock/device_lock_required_screen.dart";
import "src/screens/device_lock/device_security.dart";
import "src/screens/embedded_issuance_flows/documents/driving_licence_mrz_manual_entry_screen.dart";
import "src/screens/embedded_issuance_flows/documents/mrz_reader_screen.dart";
import "src/screens/embedded_issuance_flows/documents/nfc_reading_screen.dart";
import "src/screens/embedded_issuance_flows/documents/passport_mrz_manual_entry_screen.dart";
import "src/screens/embedded_issuance_flows/documents/widgets/driving_licence_mrz_camera_overlay.dart";
import "src/screens/embedded_issuance_flows/documents/widgets/id_card_mrz_camera_overlay.dart";
import "src/screens/embedded_issuance_flows/documents/widgets/passport_mrz_camera_overlay.dart";
import "src/screens/embedded_issuance_flows/email/email_issuance_screen.dart";
import "src/screens/embedded_issuance_flows/sms/sms_issuance_screen.dart";
import "src/screens/enrollment/enrollment_screen.dart";
import "src/screens/error/error_screen.dart";
import "src/screens/help/help_screen.dart";
import "src/screens/home/home_screen.dart";
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
import "src/widgets/irma_app_bar.dart";

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(BuildContext buildContext, WidgetRef ref) {
  final repo = IrmaRepositoryProvider.of(buildContext);
  final rootedDeviceDetector = ref.read(rootedDeviceDetectorProvider);
  final deviceLockRequirement = DeviceLockRequirement(
    ref.read(deviceSecurityProvider),
  );
  final appIntegrityGuard = AppIntegrityGuard(ref.read(appIntegrityProvider));
  // Filled in once the first integrity report is in, which is before the
  // warning it belongs to can be shown.
  IntegrityReport integrityReport = IntegrityReport.clean;
  appIntegrityGuard.firstReport.then((report) => integrityReport = report);
  final redirectionTriggers = RedirectionListenable(
    repo,
    rootedDeviceDetector,
    deviceLockRequirement,
    appIntegrityGuard,
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: [routeObserver],
    initialLocation: "/loading",
    refreshListenable: redirectionTriggers,
    errorBuilder: (context, state) => RouteNotFoundScreen(),
    routes: [
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
              return SchemalessCredentialsDetailsScreen(
                credentialTypeId: args.credentialTypeId,
              );
            },
          ),
          GoRoute(
            path: "activity_details",
            builder: (context, state) {
              final logEntry = state.extra as LogInfo;
              return ActivityDetailsScreen(
                args: ActivityDetailsScreenArgs(logEntry: logEntry),
              );
            },
          ),
          GoRoute(path: "help", builder: (context, state) => HelpScreen()),
          GoRoute(
            path: "add_data",
            builder: (context, state) => SchemalessAddDataScreen(),
            routes: [
              GoRoute(
                path: "details",
                builder: (context, state) {
                  final params = AddDataDetailsRouteParams.fromQueryParams(
                    state.uri.queryParameters,
                  );

                  return SchemalessAddDataDetailsScreen(
                    credential: params.credential,
                    faq: params.faq,
                    onCancel: context.pop,
                    onAdd: () {
                      IrmaRepositoryProvider.of(context).openIssueURL(
                        context,
                        params.credential.credentialId,
                        params.credential.issueURL,
                        ref,
                      );
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
          return SessionScreen(
            sessionId: args.sessionId,
            hasUnderlyingSession: args.hasUnderlyingSession,
          );
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
        path: "/device_lock_required",
        builder: (context, state) {
          return DeviceLockRequiredScreen(
            onOpenSettingsPressed: deviceLockRequirement.openSecuritySettings,
            onCheckAgainPressed: deviceLockRequirement.recheck,
            onContinueAnywayPressed: deviceLockRequirement.skipForDebugging,
          );
        },
      ),
      GoRoute(
        path: "/app_integrity_blocked",
        builder: (context, state) => const AppIntegrityBlockedScreen(),
      ),
      GoRoute(
        path: "/rooted_warning",
        builder: (context, state) {
          return RootedWarningScreen(
            // An emulator or a cloned app is not a modified operating system,
            // so it gets its own explanation.
            explanationTranslationKey:
                integrityReport.untrustedEnvironment &&
                    !integrityReport.modifiedDevice
                ? "rooted_warning.explanation_environment"
                : "rooted_warning.explanation",
            onAcceptRiskButtonPressed: () {
              DetectRootedDeviceIrmaPrefsRepository(
                preferences: repo.preferences,
                detector: rootedDeviceDetector,
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
        path: "/issue_mobilenumber",
        builder: (context, state) => SmsIssuanceScreen(),
      ),
      GoRoute(
        path: "/issue_email",
        builder: (context, state) => EmailIssuanceScreen(),
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
                    translationKeys: PassportMrzManualEntryTranslationKeys(
                      title: "passport.manual.title",
                      explanation: "passport.manual.explanation",
                      dateOfBirth: "passport.manual.fields.date_of_birth",
                      dateOfBirthRequired:
                          "passport.manual.fields.date_of_birth_required",
                      dateOfExpiry: "passport.manual.fields.date_of_expiry",
                      dateOfExpiryRequired:
                          "passport.manual.fields.date_of_expiry_required",
                      documentNumber: "passport.manual.fields.document_nr",
                      documentNumberRequired:
                          "passport.manual.fields.document_nr_required",
                      documentNumberInvalid:
                          "passport.manual.fields.document_nr_invalid",
                      dateInvalid: "passport.manual.fields.date_invalid",
                    ),
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
                    translationKeys: PassportMrzManualEntryTranslationKeys(
                      title: "id_card.manual.title",
                      explanation: "id_card.manual.explanation",
                      dateOfBirth: "id_card.manual.fields.date_of_birth",
                      dateOfBirthRequired:
                          "id_card.manual.fields.date_of_birth_required",
                      dateOfExpiry: "id_card.manual.fields.date_of_expiry",
                      dateOfExpiryRequired:
                          "id_card.manual.fields.date_of_expiry_required",
                      documentNumber: "id_card.manual.fields.document_nr",
                      documentNumberRequired:
                          "id_card.manual.fields.document_nr_required",
                      documentNumberInvalid:
                          "id_card.manual.fields.document_nr_invalid",
                      dateInvalid: "id_card.manual.fields.date_invalid",
                    ),
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
              GoRoute(
                path: "/residence_permit",
                builder: (context, state) {
                  return PassportMrzManualEntryScreen(
                    translationKeys: PassportMrzManualEntryTranslationKeys(
                      title: "residence_permit.manual.title",
                      explanation: "residence_permit.manual.explanation",
                      dateOfBirth:
                          "residence_permit.manual.fields.date_of_birth",
                      dateOfBirthRequired:
                          "residence_permit.manual.fields.date_of_birth_required",
                      dateOfExpiry:
                          "residence_permit.manual.fields.date_of_expiry",
                      dateOfExpiryRequired:
                          "residence_permit.manual.fields.date_of_expiry_required",
                      documentNumber:
                          "residence_permit.manual.fields.document_nr",
                      documentNumberRequired:
                          "residence_permit.manual.fields.document_nr_required",
                      documentNumberInvalid:
                          "residence_permit.manual.fields.document_nr_invalid",
                      dateInvalid:
                          "residence_permit.manual.fields.date_invalid",
                    ),
                    onCancel: context.pop,
                    onContinue: (data) {
                      context.pushResidencePermitNfcReadingScreen(
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
                        IdCardMrzCameraOverlay(success: success, child: child),
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
                    onManualAdd: context.pushIdCardManualEntryScreen,
                    onCancel: context.pop,
                    mrzParser: IdCardMrzParser(),
                  );
                },
              ),
              GoRoute(
                path: "/residence_permit",
                builder: (context, state) {
                  return MrzReaderScreen(
                    overlayBuilder: ({required success, required child}) =>
                        IdCardMrzCameraOverlay(success: success, child: child),
                    translationKeys: MrzReaderTranslationKeys(
                      title: "residence_permit.scan.title",
                      manualEntryButton: "residence_permit.scan.manual",
                      error: "residence_permit.scan.error",
                      success: "residence_permit.scan.success",
                      successExplanation:
                          "residence_permit.scan.success_explanation",
                    ),
                    onSuccess: (mrzResult) {
                      final r = mrzResult as PassportMrzResult;
                      context.pushResidencePermitNfcReadingScreen(
                        PassportNfcReadingRouteParams(
                          documentNumber: r.documentNumber,
                          dateOfBirth: r.birthDate,
                          dateOfExpiry: r.expiryDate,
                          countryCode: r.countryCode,
                        ),
                      );
                    },
                    onManualAdd: context.pushResidencePermitManualEntryScreen,
                    onCancel: context.pop,
                    mrzParser: IdCardMrzParser(),
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
                  wrongDocument: "id_card.nfc.wrong_document",
                  wrongDocumentTip: "id_card.nfc.wrong_document_tip",
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
          GoRoute(
            path: "/residence_permit",
            builder: (context, state) {
              final args = PassportNfcReadingRouteParams.fromQueryParams(
                state.uri.queryParameters,
              );
              return NfcReadingScreen(
                translationKeys: NfcReadingTranslationKeys(
                  cancelDialogTitle: "residence_permit.nfc.cancel_dialog.title",
                  cancelDialogExplanation:
                      "residence_permit.nfc.cancel_dialog.explanation",
                  cancelDialogDecline:
                      "residence_permit.nfc.cancel_dialog.decline",
                  cancelDialogConfirm:
                      "residence_permit.nfc.cancel_dialog.confirm",
                  error: "residence_permit.nfc.error",
                  errorGeneric: "residence_permit.nfc.error_generic",
                  title: "residence_permit.nfc.title",
                  nfcDisabled: "residence_permit.nfc.nfc_disabled",
                  nfcEnabled: "residence_permit.nfc.nfc_enabled",
                  introduction: "residence_permit.nfc.introduction",
                  startScanning: "residence_permit.nfc.start_scanning",
                  nfcDisabledExplanation:
                      "residence_permit.nfc.nfc_disabled_explanation",
                  holdNearPhotoPage:
                      "residence_permit.nfc.hold_near_photo_page",
                  tip1: "residence_permit.nfc.tip_1",
                  tip2: "residence_permit.nfc.tip_2",
                  tip3: "residence_permit.nfc.tip_3",
                  successExplanation:
                      "residence_permit.nfc.success_explanation",
                  cancelledByUser: "residence_permit.nfc.cancelled_by_user",
                  cancelled: "residence_permit.nfc.cancelled",
                  cancelling: "residence_permit.nfc.cancelling",
                  connecting: "residence_permit.nfc.connecting",
                  readingCardSecurity:
                      "residence_permit.nfc.reading_card_security",
                  readingDocumentData:
                      "residence_permit.nfc.reading_passport_data",
                  authenticating: "residence_permit.nfc.authenticating",
                  performingSecurityVerification:
                      "residence_permit.nfc.performing_security_verification",
                  timeoutWaitingForTag:
                      "residence_permit.nfc.timeout_waiting_for_tag",
                  tagLostTryAgain: "residence_permit.nfc.tag_lost_try_again",
                  failedToInitiateSession:
                      "residence_permit.nfc.failed_to_initiate_session",
                  success: "residence_permit.nfc.success",
                  wrongDocument: "residence_permit.nfc.wrong_document",
                  wrongDocumentTip: "residence_permit.nfc.wrong_document_tip",
                ),
                mrz: ScannedIdCardMrz(
                  documentNumber: args.documentNumber,
                  countryCode: args.countryCode ?? "",
                  dateOfBirth: args.dateOfBirth,
                  dateOfExpiry: args.dateOfExpiry,
                  documentType: .residencePermit,
                ),
                onCancel: context.goHomeScreen,
              );
            },
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      if (redirectionTriggers.value.integrityBlocked) {
        return "/app_integrity_blocked";
      }
      if (redirectionTriggers.value.deviceLockRequired) {
        return "/device_lock_required";
      }
      if (state.matchedLocation == "/device_lock_required") {
        return "/loading";
      }
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

  RedirectionListenable(
    IrmaRepository repo,
    RootedDeviceDetector detector,
    DeviceLockRequirement deviceLockRequirement,
    AppIntegrityGuard appIntegrityGuard,
  ) : super(RedirectionTriggers.withDefaults()) {
    final integrityBlockedStream = appIntegrityGuard.blocked;
    final deviceLockStream = deviceLockRequirement.lockRequired;
    final warningStream = _displayDeviceIsRootedWarning(
      repo,
      detector,
      appIntegrityGuard,
    );
    final infoStream = repo
        .getVersionInformation()
        .map<VersionInformation?>((version) => version)
        .defaultIfEmpty(null);
    final nameChangedStream = repo.preferences.getShowNameChangedNotification();
    final enrollmentStream = repo.getEnrollmentStatus();

    // combine the streams into one
    _streamSubscription = Rx.combineLatest6(
      integrityBlockedStream,
      deviceLockStream,
      warningStream,
      infoStream,
      nameChangedStream,
      enrollmentStream,
      (
        integrityBlocked,
        deviceLockRequired,
        deviceRootedWarning,
        versionInfo,
        nameChangedWarning,
        enrollment,
      ) {
        return RedirectionTriggers(
          integrityBlocked: integrityBlocked,
          deviceLockRequired: deviceLockRequired,
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
  final bool integrityBlocked;
  final bool deviceLockRequired;
  final bool showDeviceRootedWarning;
  final bool showNameChangedMessage;
  final VersionInformation? versionInformation;
  final EnrollmentStatus enrollmentStatus;

  RedirectionTriggers({
    this.integrityBlocked = false,
    this.deviceLockRequired = false,
    required this.showDeviceRootedWarning,
    required this.showNameChangedMessage,
    required this.versionInformation,
    required this.enrollmentStatus,
  });

  RedirectionTriggers.withDefaults()
    : enrollmentStatus = .undetermined,
      integrityBlocked = false,
      deviceLockRequired = false,
      showDeviceRootedWarning = false,
      showNameChangedMessage = false,
      versionInformation = null;

  RedirectionTriggers copyWith({
    bool? integrityBlocked,
    bool? deviceLockRequired,
    bool? showDeviceRootedWarning,
    bool? showNameChangedMessage,
    VersionInformation? versionInformation,
    EnrollmentStatus? enrollmentStatus,
  }) {
    return RedirectionTriggers(
      integrityBlocked: integrityBlocked ?? this.integrityBlocked,
      deviceLockRequired: deviceLockRequired ?? this.deviceLockRequired,
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
        integrityBlocked == other.integrityBlocked &&
        deviceLockRequired == other.deviceLockRequired &&
        showDeviceRootedWarning == other.showDeviceRootedWarning &&
        showNameChangedMessage == other.showNameChangedMessage &&
        versionInformation == other.versionInformation &&
        enrollmentStatus == other.enrollmentStatus;
  }

  @override
  String toString() {
    return "integrity blocked: $integrityBlocked, enroll: $enrollmentStatus, device lock required: $deviceLockRequired, rooted: $showDeviceRootedWarning, name: $showNameChangedMessage, version: $versionInformation";
  }

  @override
  int get hashCode => Object.hash(
    integrityBlocked,
    deviceLockRequired,
    showNameChangedMessage,
    showDeviceRootedWarning,
    versionInformation,
    enrollmentStatus,
  );
}

Stream<bool> _displayDeviceIsRootedWarning(
  IrmaRepository irmaRepo,
  RootedDeviceDetector detector,
  AppIntegrityGuard appIntegrityGuard,
) {
  final repo = DetectRootedDeviceIrmaPrefsRepository(
    preferences: irmaRepo.preferences,
    detector: detector,
  );
  final streamController = StreamController<bool>();
  // The same warning, accepted once, covers a rooted or jailbroken device and
  // the other environments the app's protections cannot be relied on in: a
  // hooking framework, an emulator, an app-cloning container.
  Future.wait([
    repo.isDeviceRooted(),
    appIntegrityGuard.firstReport.then((r) => r.untrustedEnvironment),
  ]).then((risks) {
    if (risks.contains(true)) {
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
