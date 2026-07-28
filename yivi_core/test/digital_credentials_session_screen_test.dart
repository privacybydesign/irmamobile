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
      "name": {"en": "verifier.example"},
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

Widget _host(IrmaRepository repo) {
  final router = GoRouter(
    initialLocation: "/session",
    routes: [
      GoRoute(
        path: "/session",
        builder: (_, _) => const SessionScreen(
          sessionId: _sessionId,
          hasUnderlyingSession: false,
        ),
      ),
      GoRoute(
        path: "/home",
        builder: (_, _) => const Scaffold(
          body: Center(child: Text("home", key: Key("home"))),
        ),
      ),
    ],
  );

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
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

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

    await _pump(tester, _host(repo));

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

    await _pump(tester, _host(repo));

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

    await _pump(tester, _host(repo));

    repo.dispatch(SessionStateEvent(sessionState: _success()));
    await _settle(tester);

    expect(
      bridge.dispatched.whereType<DigitalCredentialsResponseEvent>(),
      isEmpty,
    );
  });
}
