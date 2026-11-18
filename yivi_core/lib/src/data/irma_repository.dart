import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart" show defaultTargetPlatform;
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show ProviderListenable;
import "package:flutter_web_auth_2/flutter_web_auth_2.dart";
import "package:material_ui/material_ui.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:rxdart/rxdart.dart";
import "package:url_launcher/url_launcher.dart";
import "package:vcmrtd/vcmrtd.dart" show DocumentType;

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
import "../models/session_state.dart";
import "../models/session_user_interaction.dart";
import "../models/version_information.dart";
import "../providers/contact_issuer_api.dart";
import "../providers/passport_issuer_provider.dart";
import "../sentry/sentry.dart";
import "../util/nfc_credentials.dart";
import "activity_log_client.dart";
import "app_language.dart";
import "app_lock.dart";
import "irma_bridge.dart";
import "irma_preferences.dart";
import "pending_pointer_queue.dart";
import "session_repository.dart";

class _CredentialObtainState {
  // Credential type IDs the user kicked off an in-app launch for (via
  // openIssueURL), pending a session finish. Used at finish time to decide
  // whether to keep the user inside Yivi or hand them off to
  // clientReturnUrl / ArrowBack / send-to-background.
  final Set<String> inAppLaunchedCredentialTypes;

  _CredentialObtainState({
    this.inAppLaunchedCredentialTypes = const <String>{},
  });
}

class IrmaRepository {
  IrmaRepository({
    required IrmaBridge client,
    required this.preferences,
    this.defaultKeyshareScheme = "pbdf",
  }) : _bridge = client {
    _credentialObtainState.add(_CredentialObtainState());
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
    onAuthCallback: handleOpenID4VCIAuthCallback,
    closeInAppBrowser: closeInAppWebView,
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
  final _credentialObtainState = BehaviorSubject<_CredentialObtainState>();
  final _fatalErrorSubject = BehaviorSubject<ErrorEvent>();

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
      _credentialObtainState.close(),
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

  void bridgedDispatch(Event event) {
    if (_closed) return;
    dispatch(event);
    _bridge.dispatch(event);
  }

  /// Deletes a card from the app, in all its formats: its instance hash
  /// by format (`credentialInstanceIds`).
  void deleteCredential(Map<CredentialFormat, String> hashByFormat) =>
      bridgedDispatch(DeleteCredentialEvent(hashByFormat: hashByFormat));

  void markInAppLaunched(Iterable<String> credentialTypeIds) {
    final current = _credentialObtainState.value.inAppLaunchedCredentialTypes;
    _credentialObtainState.add(
      _CredentialObtainState(
        inAppLaunchedCredentialTypes: {...current, ...credentialTypeIds},
      ),
    );
  }

  void clearInAppLaunches() {
    _credentialObtainState.add(_CredentialObtainState());
  }

  /// True when [session] is an issuance session that issued at least one
  /// credential the user launched in-app (via [openIssueURL]). Used to keep
  /// in-app launches inside Yivi on finish instead of chasing
  /// `clientReturnUrl` or falling through to ArrowBack / send-to-background.
  bool didIssueInAppLaunchedCredential(SessionState session) {
    if (session.type != SessionType.issuance) return false;
    final launched = _credentialObtainState.value.inAppLaunchedCredentialTypes;
    if (launched.isEmpty) return false;
    return session.offeredCredentials?.any(
          (c) => launched.contains(c.credentialId),
        ) ??
        false;
  }

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

  /// Credential types whose issuer website breaks in the in-app browser, per
  /// platform: their issue URL opens in the browser outside the app.
  // TODO Remove when disclosure sessions can be started from custom tabs
  static const _externalBrowserTypes = <TargetPlatform, Set<String>>{
    TargetPlatform.iOS: {
      "pbdf.gemeente.address",
      "pbdf.gemeente.personalData",
      "pbdf.PubHubs.account",
      "irma-demo.PubHubs.account",
    },
    TargetPlatform.android: {
      "pbdf.pbdf.idin",
      // Shares iDIN's issuer website.
      "pbdf.pbdf.ageLimits",
      "pbdf.PubHubs.account",
      "irma-demo.PubHubs.account",
    },
  };

  /// Whether the issue URL of [credentialId] opens in the browser outside
  /// the app on this platform.
  static bool _issuesInExternalBrowser(String credentialId) =>
      _externalBrowserTypes[defaultTargetPlatform]?.contains(credentialId) ??
      false;

  Stream<ErrorEvent> getFatalErrors() {
    return _fatalErrorSubject.stream;
  }

  static const _iiabchannel = MethodChannel("irma.app/iiab");

  /// The base of [url] (scheme, host and port): the issuer that Yivi's own
  /// flows talk to.
  static String _issuerBase(String url) {
    final uri = Uri.parse(url);
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }

  /// Opens Yivi's own flow for [credentialId] (see [_hasEmbeddedFlow]),
  /// pointed at the issuer of [url].
  void _openEmbeddedFlow(
    BuildContext context,
    String credentialId,
    String url,
    WidgetRef ref,
  ) {
    if (!prepareEmbeddedFlow(credentialId, url, ref.read)) return;
    // E-mail addresses, phone numbers and documents are added in the
    // sheet (IssueSheet), which never comes here.
    assert(false, "${embeddedFlowOf(credentialId)} is added in the sheet");
  }

  /// The documents ([nfcRequiringCredentialIds]), the phone number and the
  /// e-mail address, in production and staging.
  static const _embeddedFlowIds = {
    ...nfcRequiringCredentialIds,
    "pbdf.sidn-pbdf.mobilenumber",
    "pbdf.sidn-pbdf.email",
    "pbdf-staging.sidn-pbdf.mobilenumber",
    "pbdf-staging.sidn-pbdf.email",
  };

  /// Whether Yivi issues [credentialId] itself, in its own screens (e-mail,
  /// phone number, documents), instead of on the issuer's website.
  bool _hasEmbeddedFlow(String credentialId) =>
      _embeddedFlowIds.contains(credentialId);

  /// Which of Yivi's own flows issues [credentialId], if any.
  EmbeddedFlow? embeddedFlowOf(String credentialId) {
    final type = credentialId.split(".").skip(1).join(".");
    return switch (type) {
      _ when !_hasEmbeddedFlow(credentialId) => null,
      "sidn-pbdf.email" => EmbeddedFlow.email,
      "sidn-pbdf.mobilenumber" => EmbeddedFlow.phone,
      _ => EmbeddedFlow.document,
    };
  }

  /// Points Yivi's own flow for [credentialId] at the issuer of [issueURL],
  /// as opening it does, but without opening its screens: for the Change
  /// sheet, which shows the steps itself. False without an issue URL.
  /// [read] reads a provider (`ref.read` of a widget or a provider).
  bool prepareEmbeddedFlow(
    String credentialId,
    String? issueURL,
    T Function<T>(ProviderListenable<T>) read,
  ) {
    final flow = embeddedFlowOf(credentialId);
    final url = issueURL ?? "";
    if (flow == null || url.isEmpty) return false;
    final base = _issuerBase(url);
    switch (flow) {
      case EmbeddedFlow.email:
        read(emailIssuerUrlProvider.notifier).set(base);
      case EmbeddedFlow.phone:
        read(smsIssuerUrlProvider.notifier).set(base);
      case EmbeddedFlow.document:
        read(passportIssuerUrlProvider.notifier).set(base);
    }
    return true;
  }

  /// Whether obtaining [credentialId] (given an issue URL) sends the user to
  /// the issuer's website: no embedded in-app flow handles it and it does not
  /// open a native app through a universal link.
  bool issuesViaWebsite(String credentialId) {
    if (_hasEmbeddedFlow(credentialId)) return false;
    return !_issuesViaUniversalLink(credentialId);
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
  bool _issuesViaUniversalLink(String credentialId) =>
      _schemeRulesSubject.valueOrNull?.ulIssueCredentialIds.contains(
        credentialId,
      ) ??
      false;

  /// Unified entry point for "user tapped Get / Reobtain inside the app
  /// and we need to take them to the issuer to obtain a credential".
  ///
  /// Called from add-data details, credential details (reobtain) and the
  /// credential card's reobtain button.
  ///
  /// Behaviour:
  /// - For known embedded scheme credentials (pbdf/pbdf-staging passport,
  ///   drivinglicence, idcard, mobilenumber, email), dispatch to the
  ///   in-app embedded flow and return — without marking the credential
  ///   as launched (the embedded flows don't go out to a browser and
  ///   back, so the finish-time pop-to-success logic doesn't apply).
  /// - Otherwise, mark the credential as launched in-app (so the
  ///   resulting issuance session's finish lands on
  ///   `IssuanceSuccessScreen` instead of `clientReturnUrl` / ArrowBack /
  ///   send-to-background) and open the URL. Universal-link credential
  ///   types go through `openURLExternally` so the OS can dispatch the
  ///   link to a registered native app (UZI register, Belastingdienst),
  ///   as do the types whose website breaks in the in-app browser on this
  ///   platform ([_externalBrowserTypes]); everything else opens in the
  ///   in-app browser.
  Future<void> openIssueURL(
    BuildContext context,
    String credentialId,
    String? issueURL,
    WidgetRef ref,
  ) async {
    // issueURL is already resolved to the effective app language by irmago.
    final url = issueURL;
    if (url == null || url.isEmpty) {
      throw UnsupportedError(
        "Credential type $credentialId does not have a suitable issue url",
      );
    }

    if (_hasEmbeddedFlow(credentialId)) {
      return _openEmbeddedFlow(context, credentialId, url, ref);
    }

    markInAppLaunched([credentialId]);

    if (_issuesViaUniversalLink(credentialId) ||
        _issuesInExternalBrowser(credentialId)) {
      return openURLExternally(url);
    }

    return openURLinAppBrowser(url);
  }

  /// Opens a link (a markdown link, a More tile, the trust sheet) in the
  /// in-app browser.
  Future<void> openURL(String url) => openURLinAppBrowser(url);

  Future<void> openURLinAppBrowser(String url) async {
    if (Platform.isAndroid) {
      await _iiabchannel.invokeMethod("open_browser", url);
    } else {
      final uri = Uri.parse(url);
      final hasOpened = await launchUrl(uri, mode: .inAppWebView);

      // Sometimes launch does not throw an exception itself on failure. Therefore, we also check the return value.
      if (!hasOpened) {
        throw Exception("url could not be opened: $url");
      }
    }
  }

  Future<void> openURLExternally(String url) async {
    // On iOS, open Safari rather than Safari view controller
    final uri = Uri.parse(url);
    final hasOpened = await launchUrl(uri, mode: .externalApplication);

    // Sometimes launch does not throw an exception itself on failure. Therefore, we also check the return value.
    if (!hasOpened) {
      throw Exception("url could not be opened: $url");
    }
  }

  /// Drive an OpenID4VCI authorization-code flow through an
  /// `ASWebAuthenticationSession` (iOS) / Chrome Custom Tab + activity callback
  /// (Android). The OAuth `redirect_uri` is the universal link
  /// `https://open.yivi.app/-/auth-callback` (set in irmago). A bounce page
  /// at that URL JS-redirects to `app.yivi.open://auth-callback?...`, which
  /// the auth session intercepts via `callbackUrlScheme`. The resulting URL
  /// is then handed off to [handleOpenID4VCIAuthCallback].
  Future<void> authenticateOpenID4VCI(String authorizationRequestUrl) async {
    final String result;
    try {
      result = await FlutterWebAuth2.authenticate(
        url: authorizationRequestUrl,
        callbackUrlScheme: "app.yivi.open",
      );
    } on PlatformException catch (e) {
      // User dismissed the browser sheet. The session stays in
      // `requestAuthorizationCode`; the pending screen lets them retry or
      // dismiss. Anything else (e.g. the browser couldn't open) bubbles up.
      if (e.code == "CANCELED") return;
      rethrow;
    }
    await handleOpenID4VCIAuthCallback(result);
  }

  Future<void> handleOpenID4VCIAuthCallback(String url) async {
    // We only parse `state` here, used to route the callback to the right
    // session. The library parses the rest of the URL on the Go side —
    // including the OAuth error case (`?state=X&error=access_denied`), which
    // has no `code` — so we forward the URL even when it carries a failure.
    final uri = Uri.parse(url);
    final state = uri.queryParameters["state"];
    if (state == null) {
      throw MissingPointer(
        details:
            'expected "state" to be present in query parameters, but wasn\'t',
      );
    }

    final session = sessions.getCurrentSessionStateByOpenID4VCIState(state);
    if (session == null) {
      throw MissingPointer(
        details: 'No session found for state value "$state"',
      );
    }

    bridgedDispatch(
      SessionUserInteractionEvent.authCallback(
        sessionId: session.id,
        callbackUrl: url,
        proceed: true,
      ),
    );
  }

  void startTestSessionFromUrl(String url) {
    final sessionPtr = Pointer.fromString(url) as SessionPointer;
    sessionPtr.continueOnSecondDevice = true;
    pendingPointers.put(sessionPtr);
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
  final sessionPtr = SessionPointer.fromJson(
    responseObject["sessionPtr"] as Map<String, dynamic>,
  );

  sessionPtr.continueOnSecondDevice = continueOnSecondDevice;
  return sessionPtr;
}

/// Yivi's own flows for the credentials it issues itself.
enum EmbeddedFlow { email, phone, document }

/// Which document issues [credentialId] (`pbdf.pbdf.passport` and its
/// staging twin, and so on), if any.
DocumentType? documentTypeOf(String credentialId) =>
    switch (credentialId.split(".").last) {
      "passport" => .passport,
      "idcard" => .identityCard,
      "residencepermit" => .residencePermit,
      "drivinglicence" => .drivingLicence,
      _ => null,
    };
