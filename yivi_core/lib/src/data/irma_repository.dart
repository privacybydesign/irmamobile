import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart" show defaultTargetPlatform;
import "package:package_info_plus/package_info_plus.dart";
import "package:rxdart/rxdart.dart";

import "../models/change_pin_events.dart";
import "../models/clear_all_data_event.dart";
import "../models/client_preferences.dart";
import "../models/credential.dart";
import "../models/credential_events.dart";
import "../models/credential_store.dart";
import "../models/enrollment_events.dart";
import "../models/enrollment_status.dart";
import "../models/error_event.dart";
import "../models/eudi_configuration.dart";
import "../models/event.dart";
import "../models/handle_url_event.dart";
import "../models/log_entry.dart";
import "../models/native_events.dart";
import "../models/scheme_rules.dart";
import "../models/session.dart";
import "../models/session_events.dart";
import "../models/session_preview.dart";
import "../models/version_information.dart";
import "../sentry/sentry.dart";
import "activity_log_client.dart";
import "app_language.dart";
import "app_lock.dart";
import "browser.dart" show closeInAppBrowser;
import "irma_bridge.dart";
import "irma_preferences.dart";
import "pending_pointer_queue.dart";
import "session_repository.dart";

class IrmaRepository {
  IrmaRepository({
    required IrmaBridge client,
    required this.preferences,
    this.defaultKeyshareScheme = "pbdf",
  }) : _bridge = client {
    _eventSubject.listen(_eventListener);
    sessions = SessionRepository(
      eventStream: _eventSubject.stream,
      dispatch: bridgedDispatch,
      preferences: preferences,
    );
    // Listen for bridge events and send them to our event subject.
    _bridgeEventSubscription = _bridge.events.listen(
      (event) => _eventSubject.add(event),
    );

    // Push the effective app language to the Go client: the initial value
    // rides on AppReadyEvent (so text and logos resolve correctly from the
    // first pull), then a SetLocaleEvent on every change. Each change also
    // has the activity log asked for again, in the new language.
    bridgedDispatch(AppReadyEvent(locale: _appLanguage.current));
    _localeSubscription = _appLanguage.changes.listen((locale) {
      bridgedDispatch(SetLocaleEvent(locale: locale));
      activityLog.notifyChanged();
    });
  }

  final IrmaPreferences preferences;
  final String defaultKeyshareScheme;

  final IrmaBridge _bridge;
  final _eventSubject = PublishSubject<Event>();

  /// The sessions: their states, and what the user does in them. Built in
  /// the constructor, after the repository's own listener, so that it sees
  /// each event after the repository did.
  late final SessionRepository sessions;

  /// Whether the lock screen shows, and the PIN that unlocks it.
  late final AppLock appLock = AppLock(
    dispatch: bridgedDispatch,
    preferences: preferences,
    defaultKeyshareScheme: defaultKeyshareScheme,
  );

  /// The session or e-mail link waiting to be started.
  late final PendingPointerQueue pendingPointers = PendingPointerQueue(
    onAuthCallback: (url) async => sessions.answerAuthCallback(url),
    closeInAppBrowser: closeInAppBrowser,
  );

  /// Questions about the activity log.
  late final ActivityLogClient activityLog = ActivityLogClient(
    send: (event) => _bridge.dispatch(event),
  );

  // Try to pipe events from the _eventSubject, otherwise you have to explicitly close the subject in close().
  final _schemeRulesSubject = BehaviorSubject<SchemeRulesEvent>();
  final _eudiConfigurationSubject = BehaviorSubject<EudiConfiguration>();
  final _credentialsSubject = BehaviorSubject<WalletCredentials>();
  final _credentialStoreSubject = BehaviorSubject<List<CredentialStoreItem>>();

  final _enrollmentStatusEventSubject =
      BehaviorSubject<EnrollmentStatusEvent>();
  final _enrollmentEventSubject = PublishSubject<EnrollmentEvent>();
  final _changePinEventSubject = PublishSubject<ChangePinBaseEvent>();
  final _preferencesSubject = BehaviorSubject<ClientPreferencesEvent>();
  final _fatalErrorSubject = BehaviorSubject<ErrorEvent>();
  // Set by a wipe and read once by the enrollment screen it lands on, which
  // confirms the deletion to the user.
  bool _walletDeleted = false;

  late final AppLanguage _appLanguage = AppLanguage(preferences);

  late StreamSubscription<Event> _bridgeEventSubscription;
  late final StreamSubscription<String> _localeSubscription;

  /// Whether [close] has been called. A closed repository accepts no further
  /// events — see [dispatch].
  bool get isClosed => _closed;
  bool _closed = false;

  Future<void> close() async {
    // Refuse events for the whole of teardown rather than only once the
    // subjects are actually closed: close() is asynchronous, and a widget
    // disposed while it is in flight would otherwise still reach a subject
    // that is about to close.
    _closed = true;
    final activityLogClosed = activityLog.close();

    // First we have to cancel the bridge event subscription
    await _bridgeEventSubscription.cancel();
    await _localeSubscription.cancel();
    await _appLanguage.close();

    // Then we can close all internal subjects
    await Future.wait([
      _eventSubject.close(),
      _schemeRulesSubject.close(),
      _eudiConfigurationSubject.close(),
      _credentialsSubject.close(),
      _credentialStoreSubject.close(),
      _enrollmentStatusEventSubject.close(),
      _enrollmentEventSubject.close(),
      _changePinEventSubject.close(),
      appLock.close(),
      _preferencesSubject.close(),
      pendingPointers.close(),
      sessions.close(),
      _fatalErrorSubject.close(),
      activityLogClosed,
      for (final preview in _previews.values) preview.close(),
    ]);
  }

  Future<void> _eventListener(Event event) async {
    activityLog.onEvent(event);
    if (event is LogAnswer) return;
    if (event is SessionPreviewEvent) {
      final preview = _previews[event.key];
      if (preview != null && !preview.isClosed) preview.add(event.preview);
    } else if (event is ErrorEvent) {
      if (event.fatal) {
        _fatalErrorSubject.add(event);
      } else {
        // Only fatal errors on start-up are caught at the moment, so we have to report other errors manually.
        reportError(event.exception, event.stack);
      }
    } else if (event is SchemeRulesEvent) {
      _schemeRulesSubject.add(event);
    } else if (event is EudiConfigurationEvent) {
      _eudiConfigurationSubject.add(event.eudiConfiguration);
    } else if (event is CredentialsEvent) {
      _credentialsSubject.add((
        credentials: event.credentials,
        problematic: event.problematic,
      ));
    } else if (event is CredentialStoreEvent) {
      _credentialStoreSubject.add(event.credentials);
    } else if (event is ChangePinBaseEvent) {
      _changePinEventSubject.add(event);
    } else if (event is EnrollmentStatusEvent) {
      _enrollmentStatusEventSubject.add(event);
      if (!event.unenrolledSchemeManagerIds.contains(defaultKeyshareScheme) &&
          !event.enrolledSchemeManagerIds.contains(defaultKeyshareScheme)) {
        dispatch(
          ErrorEvent(
            exception:
                "Expected default keyshare scheme $defaultKeyshareScheme could not be found in configuration",
            stack: "",
            fatal: true,
          ),
        );
      }
    } else if (event is EnrollmentEvent) {
      _enrollmentEventSubject.add(event);
    } else if (event is HandleURLEvent ||
        event is AppReadyAckEvent ||
        event is NewSessionEvent) {
      await pendingPointers.onEvent(event);
    } else if (event is ClearAllDataEvent) {
      _walletDeleted = true;
      preferences.clearAll();
    } else if (event is ClientPreferencesEvent) {
      _preferencesSubject.add(event);
    }
    // After the repository's own subjects, as before the lock had a class of
    // its own: a fatal error is known before the app unlocks for it.
    appLock.onEvent(event);
  }

  Stream<Event> getEvents() {
    return _eventSubject.stream;
  }

  /// Dispatches [event] to the repository's listeners.
  ///
  /// Silently drops the event once the repository is closed. Widgets outlive
  /// the repository during teardown — a State.dispose that dismisses a session
  /// runs while Flutter finalizes the tree, which is after close() — and
  /// adding to a closed subject throws from inside that finalization, which
  /// aborts it and corrupts the element tree.
  void dispatch(Event event) {
    if (_closed) return;
    _eventSubject.add(event);
  }

  /// Whether a wipe happened since the last call. Clears the flag, so the
  /// confirmation is shown once.
  bool consumeWalletDeleted() {
    final deleted = _walletDeleted;
    _walletDeleted = false;
    return deleted;
  }

  void bridgedDispatch(BridgeEvent event) {
    if (_closed) return;
    dispatch(event);
    _bridge.dispatch(event);
  }

  /// Deletes a card from the app, in all its formats: its instance hash
  /// by format (`credentialInstanceIds`).
  void deleteCredential(Map<CredentialFormat, String> hashByFormat) =>
      bridgedDispatch(DeleteCredentialEvent(hashByFormat: hashByFormat));

  // -- Cert manager
  EudiConfiguration get eudiConfiguration => _eudiConfigurationSubject.value;

  Stream<EudiConfiguration> getEudiConfiguration() {
    return _eudiConfigurationSubject.stream;
  }

  // -- Credential instances
  Stream<WalletCredentials> getCredentials() {
    return _credentialsSubject.stream;
  }

  Stream<List<CredentialStoreItem>> getCredentialStoreItems() {
    return _credentialStoreSubject.stream;
  }

  // -- Enrollment
  Future<EnrollmentEvent> enroll({
    required String email,
    required String pin,
    required String language,
  }) {
    appLock.clear();

    bridgedDispatch(
      EnrollEvent(
        email: email,
        pin: pin,
        language: language,
        schemeId: defaultKeyshareScheme,
      ),
    );

    return _enrollmentEventSubject.where((event) {
      switch (event) {
        case EnrollmentSuccessEvent():
          preferences.longPin.set(pin.length != 5);
          return true;
        case EnrollmentFailureEvent():
          return true;
        default:
          return false;
      }
    }).first;
  }

  Stream<EnrollmentStatus> getEnrollmentStatus() async* {
    if (!_enrollmentStatusEventSubject.hasValue) {
      yield EnrollmentStatus.undetermined;
    }

    yield* _enrollmentStatusEventSubject.map((event) {
      if (event.enrolledSchemeManagerIds.contains(defaultKeyshareScheme)) {
        return EnrollmentStatus.enrolled;
      } else if (event.unenrolledSchemeManagerIds.contains(
        defaultKeyshareScheme,
      )) {
        return EnrollmentStatus.unenrolled;
      } else {
        return EnrollmentStatus.undetermined;
      }
    });
  }

  Stream<EnrollmentStatusEvent> getEnrollmentStatusEvent() =>
      _enrollmentStatusEventSubject.stream;

  void setDeveloperMode(bool enabled) {
    bridgedDispatch(
      ClientPreferencesEvent(
        clientPreferences: ClientPreferences(developerMode: enabled),
      ),
    );
  }

  Future<ChangePinBaseEvent> changePin(String oldPin, String newPin) {
    bridgedDispatch(ChangePinEvent(oldPin: oldPin, newPin: newPin));

    return _changePinEventSubject.where((event) {
      switch (event) {
        case ChangePinSuccessEvent():
          // Change pin length
          preferences.longPin.set(newPin.length != 5);
          return true;
        case ChangePinFailedEvent() || ChangePinErrorEvent():
          return true;
        default:
          return false;
      }
    }).first;
  }

  // -- Version information
  Stream<VersionInformation> getVersionInformation() async* {
    final packageInfo = await PackageInfo.fromPlatform();

    yield* _schemeRulesSubject
        .map((rules) {
          // defaultTargetPlatform is the phone's platform in the app and can
          // be set in tests. Off Android and iOS (only in tests) no scheme
          // asks for a minimum.
          final minimumBuild = rules.minimumAppVersion.forPlatform(
            defaultTargetPlatform,
          );
          final currentBuild =
              int.tryParse(packageInfo.buildNumber) ?? minimumBuild;

          return VersionInformation(
            availableVersion: minimumBuild,
            requiredVersion: minimumBuild,
            currentVersion: currentBuild,
          );
        })
        // When a fatal error occurs, no new scheme rules will come anymore. This means we can close the stream.
        .takeUntil(_fatalErrorSubject);
  }

  /// Previews asked of irmago, by pointer URL.
  final _previews = <String, BehaviorSubject<SessionPreview>>{};

  /// What [pointer] would start and who it is from, worked out by irmago
  /// without contacting a server: first what the pointer itself says, then
  /// irmago's answer. Asked once per pointer URL.
  Stream<SessionPreview> previewSession(SessionPointer pointer) {
    final existing = _previews[pointer.u];
    if (existing != null) return existing.stream;
    final preview = BehaviorSubject.seeded(SessionPreview.ofPointer(pointer));
    _previews[pointer.u] = preview;
    if (!_closed) {
      _bridge.dispatch(PreviewSessionEvent(key: pointer.u, request: pointer));
    }
    return preview.stream;
  }

  Stream<bool> getDeveloperMode() {
    return _preferencesSubject.stream.map(
      (pref) => pref.clientPreferences.developerMode,
    );
  }

  Stream<ErrorEvent> getFatalErrors() {
    return _fatalErrorSubject.stream;
  }

  /// Whether the issue URL of [credentialId] is a universal link, which the
  /// OS hands to a registered native app (UZI register, Belastingdienst).
  // TODO: surface `isULIssueUrl` on the credential models
  // (CredentialDescriptor / Credential), so the bridge need not send the
  // list in the scheme rules. Affected credentials (none overlap with the
  // embedded flows): pbdf.minvws-cibg.pilot-2,
  // pbdf.bzkpilot.personalData/.address, plus several irma-demo demo creds
  // (digidproef.*, uzipoc-cibg.*). Before the first scheme rules, and for
  // credentials not in them, false.
  bool issuesViaUniversalLink(String credentialId) =>
      _schemeRulesSubject.valueOrNull?.ulIssueCredentialIds.contains(
        credentialId,
      ) ??
      false;

  void startTestSessionFromUrl(String url) {
    final sessionPtr = Pointer.fromString(url) as SessionPointer;
    pendingPointers.put(sessionPtr.copyWith(continueOnSecondDevice: true));
  }

  /// Only meant for testing and debug purposes.
  Future<void> startTestSession(
    String requestBody, {
    continueOnSecondDevice = true,
  }) async {
    final sessionPtr = await createTestSession(
      requestBody,
      continueOnSecondDevice: continueOnSecondDevice,
    );
    pendingPointers.put(sessionPtr);
  }
}

Future<SessionPointer> createTestSession(
  String requestBody, {
  bool continueOnSecondDevice = true,
}) async {
  final Uri uri = Uri.parse("https://is.demo.staging.yivi.app/session");

  final request = await HttpClient().postUrl(uri);
  request.headers.set("Content-Type", "application/json");
  request.write(requestBody);

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).first;

  if (response.statusCode != 200) {
    throw "Status ${response.statusCode}: $responseBody";
  }

  final responseObject = jsonDecode(responseBody) as Map<String, dynamic>;
  return SessionPointer.fromJson(
    responseObject["sessionPtr"] as Map<String, dynamic>,
  ).copyWith(continueOnSecondDevice: continueOnSecondDevice);
}
