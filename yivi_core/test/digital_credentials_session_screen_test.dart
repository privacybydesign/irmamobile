import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/digital_credentials.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/schemaless/session_user_interaction.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

class _RecordingBridge extends IrmaBridge {
  final dispatched = <Event>[];

  @override
  void dispatch(Event event) => dispatched.add(event);
}

const _sessionId = 42;
const _response = '{"vp_token":{"pid":["eyJ.eyJ.sig~"]}}';

/// A finished OpenID4VP disclosure. Carries [dcApiResponse] when it was started
/// from a Digital Credentials API request; a session that arrived as a URL has
/// none, and the return-URL / ArrowBack handling applies instead.
SessionState _success({String? dcApiResponse}) => SessionState.fromJson(
  jsonDecode('''
  {
    "id": $_sessionId,
    "protocol": "openid4vp",
    "type": "disclosure",
    "status": "success",
    "requestor": {
      "id": "",
      "name": "verifier.example",
      "url": null,
      "parent": null,
      "verified": false
    },
    "offered_credential_types": null
    ${dcApiResponse == null ? "" : ', "dc_api_response": ${jsonEncode(dcApiResponse)}'}
  }
  ''')
      as Map<String, dynamic>,
);

/// A session that ended without an Authorization Response: the user closed it,
/// or it failed. Neither state carries a `dc_api_response`, so the screen can
/// only tell these apart from a URL-started session by what the repository
/// remembers about the session id.
SessionState _ended({required bool failed}) => SessionState.fromJson(
  jsonDecode('''
  {
    "id": $_sessionId,
    "protocol": "openid4vp",
    "type": "disclosure",
    "status": "${failed ? "error" : "dismissed"}",
    "requestor": {
      "id": "",
      "name": "verifier.example",
      "url": null,
      "parent": null,
      "verified": false
    },
    "offered_credential_types": null
    ${failed ? ', "error": {"error_type": "transport", "info": "no route to host"}' : ""}
  }
  ''')
      as Map<String, dynamic>,
);

/// The session screen sits on top of the home screen, as it does in the app: a
/// Digital Credentials request is queued as a pending pointer and pushed from
/// there. The dismissed ending pops rather than navigating, so it needs
/// something underneath to pop back to.
GoRouter _router() => GoRouter(
  initialLocation: "/home",
  routes: [
    GoRoute(
      path: "/home",
      builder: (_, _) => const Scaffold(
        body: Center(child: Text("home", key: Key("home"))),
      ),
    ),
    GoRoute(
      path: "/session",
      builder: (_, _) => const SessionScreen(
        sessionId: _sessionId,
        hasUnderlyingSession: false,
      ),
    ),
  ],
);

Widget _host(IrmaRepository repo, GoRouter router) {
  return ProviderScope(
    overrides: [irmaRepositoryProvider.overrideWithValue(repo)],
    child: IrmaRepositoryProvider(
      repository: repo,
      child: IrmaTheme(
        builder: (_) => MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: const Locale("en", "EN"),
              ),
            ),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    ),
  );
}

/// Pump a few frames. The session screen shows a continuously animating loading
/// indicator, so `pumpAndSettle` never returns here.
Future<void> _settle(WidgetTester tester, {int frames = 5}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Pump past the route transition that takes the session screen away, so its
/// `dispose` has actually run. Five frames only get partway through it, and the
/// screen keeps animating while it is still on screen, so this cannot settle.
Future<void> _settleAfterLeaving(WidgetTester tester) =>
    _settle(tester, frames: 20);

/// Mount the session screen and wait for FlutterI18nDelegate to finish reading
/// the locale JSON. The loader does real-time file IO that the test framework's
/// fake clock never drives, so `runAsync` with a real delay is needed before the
/// tree renders anything (see signature_message_widget_test.dart).
Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await _settle(tester);
}

/// Mount the app on the home screen and push the session screen onto it, the way
/// a queued pointer does. Returns the router, so a test can leave the session
/// screen the way the error screen's close handler does.
Future<GoRouter> _pumpSession(WidgetTester tester, IrmaRepository repo) async {
  final router = _router();
  await _pump(tester, _host(repo, router));
  router.push("/session");
  await _settle(tester);
  return router;
}

void main() {
  Future<IrmaRepository> repository(_RecordingBridge bridge) async {
    SharedPreferences.setMockInitialValues({});
    return IrmaRepository(
      client: bridge,
      preferences: await IrmaPreferences.fromInstance(
        mostRecentTermsUrlNl: "",
        mostRecentTermsUrlEn: "",
      ),
    );
  }

  // The platform, not the wallet, hands the Authorization Response to the
  // verifier and returns the user to the caller. So on success the screen has
  // exactly one job: give the response to native.
  testWidgets("a finished Digital Credentials session returns the response to "
      "native and leaves the screen", (tester) async {
    final bridge = _RecordingBridge();
    final repo = await repository(bridge);
    // Unmount before closing: SessionScreen.dispose dispatches on the
    // repository, which must still be open at that point.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await repo.close();
    });

    await _pumpSession(tester, repo);

    repo.dispatch(
      SessionStateEvent(sessionState: _success(dcApiResponse: _response)),
    );
    await _settle(tester);

    final responses = bridge.dispatched
        .whereType<DigitalCredentialsResponseEvent>()
        .map((e) => e.response);
    expect(responses, [_response]);

    // The success screen is skipped: there is nothing to confirm in-app.
    expect(find.byKey(const Key("home")), findsOneWidget);
  });

  // Regression guard for the response event: the success screen rebuilds, and a
  // verifier must never receive the same presentation twice.
  testWidgets("the response is handed over only once across rebuilds", (
    tester,
  ) async {
    final bridge = _RecordingBridge();
    final repo = await repository(bridge);
    // Unmount before closing: SessionScreen.dispose dispatches on the
    // repository, which must still be open at that point.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await repo.close();
    });

    await _pumpSession(tester, repo);

    for (var i = 0; i < 3; i++) {
      repo.dispatch(
        SessionStateEvent(sessionState: _success(dcApiResponse: _response)),
      );
      await _settle(tester);
    }

    expect(
      bridge.dispatched.whereType<DigitalCredentialsResponseEvent>().length,
      1,
    );
  });

  // A session that arrived as a URL must keep its existing ending: no response
  // is handed to native, so the platform is never told about a session it did
  // not start.
  testWidgets("a session without a Digital Credentials response sends none", (
    tester,
  ) async {
    final bridge = _RecordingBridge();
    final repo = await repository(bridge);
    // Unmount before closing: SessionScreen.dispose dispatches on the
    // repository, which must still be open at that point.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await repo.close();
    });

    await _pumpSession(tester, repo);

    repo.dispatch(SessionStateEvent(sessionState: _success()));
    await _settle(tester);

    expect(
      bridge.dispatched.whereType<DigitalCredentialsResponseEvent>(),
      isEmpty,
    );
  });

  // The platform holds the caller's navigator.credentials.get() open until
  // native answers it, and nothing else in the app closes a session the user
  // walked away from. These are the endings that produce no response.
  group("a Digital Credentials session that ends without a response", () {
    testWidgets("reports a cancellation when the user closes it", (
      tester,
    ) async {
      final bridge = _RecordingBridge();
      final repo = await repository(bridge);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
      });

      await _pumpSession(tester, repo);
      repo.markDigitalCredentialsSession(_sessionId);

      repo.dispatch(SessionStateEvent(sessionState: _ended(failed: false)));
      await _settleAfterLeaving(tester);

      // The dismissed branch pops the session screen by itself.
      expect(find.byKey(const Key("home")), findsOneWidget);
      expect(find.byType(SessionScreen), findsNothing);
      expect(
        bridge.dispatched.whereType<DigitalCredentialsFailureEvent>().map(
          (e) => e.reason,
        ),
        [DigitalCredentialsFailureReason.cancelled],
      );
      expect(
        bridge.dispatched.whereType<DigitalCredentialsResponseEvent>(),
        isEmpty,
      );
    });

    testWidgets("reports an error when the session failed", (tester) async {
      final bridge = _RecordingBridge();
      final repo = await repository(bridge);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
      });

      final router = await _pumpSession(tester, repo);
      repo.markDigitalCredentialsSession(_sessionId);

      repo.dispatch(SessionStateEvent(sessionState: _ended(failed: true)));
      await _settle(tester);

      // The error screen stays up until the user closes it, and its close
      // handler goes to the home screen rather than finishing anything.
      expect(
        bridge.dispatched.whereType<DigitalCredentialsFailureEvent>(),
        isEmpty,
      );

      router.go("/home");
      await _settleAfterLeaving(tester);

      expect(
        bridge.dispatched.whereType<DigitalCredentialsFailureEvent>().map(
          (e) => e.reason,
        ),
        [DigitalCredentialsFailureReason.error],
      );
    });

    testWidgets("reports a cancellation when the user leaves before any state "
        "arrives", (tester) async {
      final bridge = _RecordingBridge();
      final repo = await repository(bridge);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
      });

      final router = await _pumpSession(tester, repo);
      repo.markDigitalCredentialsSession(_sessionId);

      router.go("/home");
      await _settleAfterLeaving(tester);

      expect(
        bridge.dispatched.whereType<DigitalCredentialsFailureEvent>().map(
          (e) => e.reason,
        ),
        [DigitalCredentialsFailureReason.cancelled],
      );
      // The session does exist on the Go side, so it is still dismissed there.
      expect(
        bridge.dispatched.whereType<SessionUserInteractionEvent>(),
        isNotEmpty,
      );
    });

    testWidgets("stays quiet for a session that arrived as a URL", (
      tester,
    ) async {
      final bridge = _RecordingBridge();
      final repo = await repository(bridge);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
      });

      await _pumpSession(tester, repo);

      repo.dispatch(SessionStateEvent(sessionState: _ended(failed: false)));
      await _settleAfterLeaving(tester);

      expect(
        bridge.dispatched.whereType<DigitalCredentialsFailureEvent>(),
        isEmpty,
      );
    });

    // Both legs claim the same outcome, so a finished session cannot also be
    // reported as cancelled when its screen goes away.
    testWidgets("is not also reported after the response was handed over", (
      tester,
    ) async {
      final bridge = _RecordingBridge();
      final repo = await repository(bridge);
      addTearDown(repo.close);

      await _pumpSession(tester, repo);
      repo.markDigitalCredentialsSession(_sessionId);

      repo.dispatch(
        SessionStateEvent(sessionState: _success(dcApiResponse: _response)),
      );
      await _settle(tester);
      await tester.pumpWidget(const SizedBox.shrink());

      expect(
        bridge.dispatched.whereType<DigitalCredentialsResponseEvent>().length,
        1,
      );
      expect(
        bridge.dispatched.whereType<DigitalCredentialsFailureEvent>(),
        isEmpty,
      );
    });
  });
}
