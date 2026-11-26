import "dart:async";

import "package:flutter/semantics.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/routing.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/data/keyshare_email_link_api.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/credential_store.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/log_entry.dart" show CredentialFormat;
import "package:yivi_core/src/models/handle_url_event.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/providers/contact_issuance_provider.dart";
import "package:yivi_core/src/providers/contact_issuer_api_provider.dart";
import "package:yivi_core/src/providers/credentials_provider.dart";
import "package:yivi_core/src/providers/email_linking_provider.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/session_launcher.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/routing/navigation.dart";
import "package:yivi_core/src/screens/add_data/add_data_sheet.dart";
import "package:yivi_core/src/screens/add_data/email_linking.dart";
import "package:yivi_core/src/screens/add_data/secure_app.dart";
import "package:yivi_core/src/providers/session_user_choices_provider.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/layout/legacy_material_bridge.dart";

class _SilentBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

class _FakeEmailIssuerApi implements ContactIssuerApi {
  final sent = <String>[];
  final verified = <({String email, String code})>[];
  Object? verifyFailsWith;

  @override
  Future<void> send({required String target, required String language}) async {
    sent.add(target);
  }

  @override
  Future<SessionPointer> verify({
    required String target,
    required String code,
  }) async {
    verified.add((email: target, code: code));
    if (verifyFailsWith != null) throw verifyFailsWith!;
    return SessionPointer(
      u: "https://email-issuer.example/irma/session/abc",
      irmaqr: "issuing",
      protocol: Protocol.irma,
      continueOnSecondDevice: true,
    );
  }
}

class _FakeKeyshareLinkApi implements KeyshareEmailLinkApi {
  int calls = 0;
  Object? failWith;

  @override
  Future<SessionPointer> startSession() async {
    calls++;
    if (failWith != null) throw failWith!;
    return SessionPointer(
      u: "https://keyshare.example/irma/session/def",
      irmaqr: "disclosing",
      protocol: Protocol.irma,
      continueOnSecondDevice: true,
    );
  }
}

// Not a session id the flow allocates itself (those count up from 1).
const _issuanceSessionId = 100;

final _requestor = TrustedParty(
  id: "pbdf.sidn-pbdf.email",
  name: "Yivi",
  url: null,
  parent: null,
  verified: true,
);

SessionState _successState(int id, SessionType type) => SessionState(
  id: id,
  protocol: "irma",
  type: type,
  status: SessionStatus.success,
  requestor: _requestor,
  continueOnSecondDevice: true,
);

/// What the home screen does with a link: [SessionLauncher.handle], and the
/// linking screens opened when it asks for them.
void _handle(BuildContext context, Pointer pointer) {
  final outcome = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(sessionLauncherProvider).handle(pointer);
  if (outcome case LinkForLinking(openLinking: true)) {
    openEmailLinking(context);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;

  /// Whether the keyshare server's link endpoint is known.
  var linkingOffered = false;
  late IrmaRepository repo;
  late _FakeEmailIssuerApi issuerApi;
  late _FakeKeyshareLinkApi linkApi;
  late ProviderContainer container;
  late GoRouter router;

  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  setUp(() async {
    // The repository closes the in-app browser when a link opens the app.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("plugins.flutter.io/url_launcher"),
          (call) async => null,
        );

    prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
    repo = IrmaRepository(client: _SilentBridge(), preferences: prefs);
    issuerApi = _FakeEmailIssuerApi();
    linkApi = _FakeKeyshareLinkApi();
    linkingOffered = false;
  });

  // Mirrors the routes the flow uses in routing.dart: the real router builds
  // the whole home screen, which needs far more setup than this test.
  Future<void> pumpApp(
    WidgetTester tester, {
    Widget? home,
    List<Override> overrides = const [],
  }) async {
    router = GoRouter(
      initialLocation: "/home",
      // The code screen starts over when a page above it closes.
      observers: [routeObserver],
      routes: [
        GoRoute(
          path: "/home",
          builder: (context, state) =>
              home ??
              Scaffold(
                body: Builder(
                  builder: (context) => Column(
                    children: [
                      const Text("home"),
                      TextButton(
                        key: const Key("open_linking"),
                        onPressed: () => openEmailLinking(context),
                        child: const Text("link"),
                      ),
                    ],
                  ),
                ),
              ),
        ),
        GoRoute(
          path: "/session",
          builder: (context, state) {
            final params = SessionRouteParams.fromQueryParams(
              state.uri.queryParameters,
            );
            return SessionScreen(sessionId: params.sessionId);
          },
        ),
        GoRoute(
          path: "/error",
          builder: (context, state) {
            return Scaffold(body: Text(state.extra as String));
          },
        ),
      ],
    );

    container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        irmaRepositoryProvider.overrideWithValue(repo),
        emailIssuerApiProvider.overrideWithValue(issuerApi),
        keyshareEmailLinkApiProvider.overrideWithValue(linkApi),
        emailLinkingOfferedProvider.overrideWithValue(linkingOffered),
        // Sessions started through the launcher go on this router.
        routerProvider.overrideWithValue(router),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);

    final widget = UncontrolledProviderScope(
      container: container,
      child: YiviTheme(
        builder: (_) => MaterialApp.router(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: const Locale("en", "US"),
              ),
            ),
            ...GlobalMaterialLocalizations.delegates,
          ],
          builder: (context, child) => LegacyMaterialBridge(child: child!),
          routerConfig: router,
        ),
      ),
    );

    // FileTranslationLoader reads the locale JSON with real IO, which the test
    // framework's fake clock does not drive.
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    repo.dispatch(
      CredentialStoreEvent(
        credentials: [
          CredentialStoreItem(
            credential: CredentialDescriptor(
              credentialId: "pbdf.sidn-pbdf.email",
              name: "Email address",
              issuer: _requestor,
              category: null,
              attributes: const [],
              issueURL: "https://email-issuer.example/issue",
            ),
            faq: Faq(intro: null, purpose: null, content: null, howTo: null),
          ),
        ],
      ),
    );
  }

  final sheet = find.byKey(const Key("add_data_sheet"));

  // Preference and repository streams finish on the real event loop.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  // Storage streams finish on the real event loop, not the test's fake clock.
  Future<T?> stored<T>(WidgetTester tester, Stream<T> stream) =>
      tester.runAsync(() => stream.first);

  List<int> openSessions(WidgetTester tester) => tester
      .widgetList<SessionScreen>(find.byType(SessionScreen))
      .map((screen) => screen.sessionId)
      .toList();

  Future<void> openLinkingFlow(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key("open_linking")));
    await settle(tester);
    await settle(tester);
  }

  Future<void> sendEmailTo(WidgetTester tester, String address) async {
    await tester.enterText(find.byKey(const Key("email_input_field")), address);
    await tester.pump();
    await tester.tap(find.byKey(const Key("contact_sheet_send")).last);
    await settle(tester);
    await settle(tester);
  }

  /// "Check code" on the code page.
  Future<void> checkCode(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key("contact_sheet_verify")).last);
    await settle(tester);
  }

  group("code link in the e-mail", () {
    test("is queued as a pointer", () async {
      repo.dispatch(
        HandleURLEvent(
          url:
              "https://open.yivi.app/-/email#code=ABC123&email=jan%40example.com",
        ),
      );
      final pointer = await repo.pendingPointers.pending
          .firstWhere((p) => p != null)
          .timeout(const Duration(seconds: 2));

      expect(pointer, isA<EmailCodePointer>());
      expect((pointer as EmailCodePointer).code, "ABC123");
      expect(pointer.email, "jan@example.com");
    });
  });

  group("the linking sheet", () {
    testWidgets("opens on the address with the linking copy", (tester) async {
      await pumpApp(tester);
      await openLinkingFlow(tester);

      expect(sheet, findsOneWidget);
      expect(find.text("Link your email address"), findsOneWidget);
      expect(
        find.textContaining("Then you can block your Yivi app"),
        findsOneWidget,
      );
      expect(find.byKey(const Key("email_input_field")), findsOneWidget);
    });

    testWidgets("sending the address opens the code page", (tester) async {
      await pumpApp(tester);
      await openLinkingFlow(tester);

      await sendEmailTo(tester, "jan@example.com");

      expect(issuerApi.sent, ["jan@example.com"]);
      expect(find.text("Code from the e-mail"), findsOneWidget);
      expect(
        find.textContaining("We've sent an email to jan@example.com"),
        findsOneWidget,
      );
    });

    testWidgets("a typed code checks itself once complete", (tester) async {
      await pumpApp(tester);
      await openLinkingFlow(tester);
      await sendEmailTo(tester, "jan@example.com");

      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        "abc12",
      );
      await tester.pump();
      expect(issuerApi.verified, isEmpty);

      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        "abc123",
      );
      await settle(tester);

      expect(issuerApi.verified, [(email: "jan@example.com", code: "ABC123")]);
      // The issuance shows in the sheet, not on a session screen.
      expect(openSessions(tester), isEmpty);
      expect(sheet, findsOneWidget);
    });
  });

  group("link while the flow is open", () {
    testWidgets("for the address typed: checked at once", (tester) async {
      await pumpApp(tester);
      await openLinkingFlow(tester);
      await sendEmailTo(tester, "jan@example.com");

      container
          .read(emailLinkingProvider.notifier)
          .receiveLink(
            EmailCodePointer(email: "jan@example.com", code: "XYZ789"),
          );
      await settle(tester);

      // Checked at once: the sheet goes on to the issuance.
      expect(issuerApi.verified, [(email: "jan@example.com", code: "XYZ789")]);
      expect(container.read(emailLinkingProvider).link, isNull);
    });

    testWidgets("opens the linking screens when they are not open yet", (
      tester,
    ) async {
      linkingOffered = true;
      await pumpApp(tester);
      final context = tester.element(find.text("home"));

      _handle(
        context,
        EmailCodePointer(email: "jan@example.com", code: "XYZ789"),
      );
      await settle(tester);
      await settle(tester);

      expect(sheet, findsOneWidget);
      expect(find.text("Code from the e-mail"), findsOneWidget);
      // The code went to the link's address.
      expect(
        find.textContaining("jan@example.com", findRichText: true),
        findsWidgets,
      );
      expect(issuerApi.sent, isEmpty);
      expect(find.text("Code filled in from the link"), findsOneWidget);
      expect(issuerApi.verified, isEmpty);

      await checkCode(tester);

      expect(issuerApi.verified, [(email: "jan@example.com", code: "XYZ789")]);
    });

    testWidgets("is dropped when linking is not offered", (tester) async {
      await pumpApp(tester);
      _handle(
        tester.element(find.text("home")),
        EmailCodePointer(email: "jan@example.com", code: "XYZ789"),
      );
      await settle(tester);
      await settle(tester);

      expect(sheet, findsNothing);
      expect(container.read(emailLinkingProvider).link, isNull);
    });

    testWidgets("is cleared from the queue once handled", (tester) async {
      await pumpApp(tester);
      final context = tester.element(find.text("home"));
      final link = EmailCodePointer(email: "jan@example.com", code: "XYZ789");
      issuerApi.verifyFailsWith = const ContactWrongCode();

      repo.pendingPointers.put(link);
      _handle(context, link);
      await settle(tester);

      expect(repo.pendingPointers.current, isNull);
    });

    testWidgets("for another address waits for a tap on Check code", (
      tester,
    ) async {
      await pumpApp(tester);
      await openLinkingFlow(tester);
      await sendEmailTo(tester, "jan@example.com");

      container
          .read(emailLinkingProvider.notifier)
          .receiveLink(
            EmailCodePointer(email: "other@example.com", code: "XYZ789"),
          );
      await settle(tester);

      expect(find.text("Code filled in from the link"), findsOneWidget);
      expect(
        find.textContaining("other@example.com", findRichText: true),
        findsWidgets,
      );
      expect(issuerApi.verified, isEmpty);

      await checkCode(tester);

      expect(issuerApi.verified, [
        (email: "other@example.com", code: "XYZ789"),
      ]);
    });

    testWidgets("twice for another address still waits for a tap", (
      tester,
    ) async {
      await pumpApp(tester);
      await openLinkingFlow(tester);
      await sendEmailTo(tester, "jan@example.com");

      for (final code in ["AAA111", "BBB222"]) {
        container
            .read(emailLinkingProvider.notifier)
            .receiveLink(
              EmailCodePointer(email: "evil@example.com", code: code),
            );
        await settle(tester);
      }

      expect(issuerApi.verified, isEmpty);

      await checkCode(tester);

      expect(issuerApi.verified, [(email: "evil@example.com", code: "BBB222")]);
    });

    testWidgets("twice when the flow was closed still waits for a tap", (
      tester,
    ) async {
      linkingOffered = true;
      await pumpApp(tester);
      final context = tester.element(find.text("home"));

      _handle(
        context,
        EmailCodePointer(email: "evil@example.com", code: "AAA111"),
      );
      await settle(tester);
      await settle(tester);
      _handle(
        tester.element(sheet),
        EmailCodePointer(email: "evil@example.com", code: "BBB222"),
      );
      await settle(tester);

      expect(issuerApi.verified, isEmpty);
    });

    testWidgets("without an address, fills in the code for the address the "
        "user typed and continues on its own", (tester) async {
      await pumpApp(tester);
      await openLinkingFlow(tester);
      await sendEmailTo(tester, "jan@example.com");

      container
          .read(emailLinkingProvider.notifier)
          .receiveLink(EmailCodePointer(code: "XYZ789"));
      await settle(tester);

      expect(issuerApi.verified, [(email: "jan@example.com", code: "XYZ789")]);
      expect(container.read(emailLinkingProvider).link, isNull);
    });

    testWidgets("without an address, opens the flow at the address when it "
        "was closed", (tester) async {
      linkingOffered = true;
      await pumpApp(tester);
      final context = tester.element(find.text("home"));

      _handle(context, EmailCodePointer(code: "XYZ789"));
      await settle(tester);
      await settle(tester);

      expect(sheet, findsOneWidget);
      expect(find.text("Link your email address"), findsOneWidget);
      expect(find.text("Code from the e-mail"), findsNothing);
      expect(issuerApi.verified, isEmpty);
      expect(container.read(emailLinkingProvider).link, isNull);
    });

    testWidgets("is applied once when the flow is already open", (
      tester,
    ) async {
      await pumpApp(tester);
      await openLinkingFlow(tester);
      await sendEmailTo(tester, "jan@example.com");
      final context = tester.element(find.text("Code from the e-mail"));

      _handle(
        context,
        EmailCodePointer(email: "jan@example.com", code: "XYZ789"),
      );
      await settle(tester);

      expect(sheet, findsOneWidget);
      expect(issuerApi.verified, hasLength(1));
    });
  });

  group("hand-over to the keyshare server", () {
    Future<void> pumpSession(WidgetTester tester, int id) async {
      await pumpApp(
        tester,
        overrides: [
          sessionStateProvider.overrideWith(
            (ref, sessionId) => Stream.value(
              _successState(
                sessionId,
                sessionId == _issuanceSessionId
                    ? SessionType.issuance
                    : SessionType.disclosure,
              ),
            ),
          ),
        ],
      );
      router.push("/session?session_id=$id");
      await tester.pump();
      await settle(tester);
    }

    /// The first session is the e-mail's issuance in the sheet, which
    /// succeeds; the next the keyshare disclosure, which answers after its
    /// screen has been pushed.
    List<Override> sessions() {
      int? issuance;
      return [
        sessionStateProvider.overrideWith((ref, id) {
          issuance ??= id;
          return id == issuance
              ? Stream.value(_successState(id, SessionType.issuance))
              : Stream.fromFuture(
                  Future.delayed(
                    const Duration(milliseconds: 50),
                    () => _successState(id, SessionType.disclosure),
                  ),
                );
        }),
      ];
    }

    Future<void> linkTheAddress(WidgetTester tester) async {
      await openLinkingFlow(tester);
      await sendEmailTo(tester, "jan@example.com");
      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        "ABC123",
      );
      for (var i = 0; i < 4; i++) {
        await settle(tester);
      }
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets("once added in the sheet, the sheet goes and the keyshare "
        "disclosure comes up", (tester) async {
      await pumpApp(tester, overrides: sessions());
      await linkTheAddress(tester);

      expect(linkApi.calls, 1);
      expect(sheet, findsNothing);
      expect(
        find.text("The data has been successfully added to Yivi"),
        findsNothing,
      );
      expect(openSessions(tester), [2]);
      expect(container.read(emailLinkingProvider).disclosureSessionId, 2);
      expect(find.text("Email address linked"), findsOneWidget);
      expect(await stored(tester, prefs.emailLinked.stream), isTrue);
    });

    testWidgets("an issuance that is not part of the flow ends as today", (
      tester,
    ) async {
      await pumpSession(tester, _issuanceSessionId);

      expect(linkApi.calls, 0);
      expect(
        find.text("The data has been successfully added to Yivi"),
        findsOneWidget,
      );
      expect(await stored(tester, prefs.emailLinked.stream), isFalse);
    });

    testWidgets("a disclosure that is not part of the flow links nothing", (
      tester,
    ) async {
      await pumpSession(tester, 5);

      expect(find.text("Email address linked"), findsNothing);
      expect(await stored(tester, prefs.emailLinked.stream), isFalse);
    });

    testWidgets("an unreachable keyshare server ends on the error screen", (
      tester,
    ) async {
      linkApi.failWith = KeyshareEmailLinkUnavailable();
      await pumpApp(tester, overrides: sessions());
      await linkTheAddress(tester);

      expect(
        find.textContaining("error linking e-mail address"),
        findsOneWidget,
      );
      expect(openSessions(tester), isEmpty);
      expect(await stored(tester, prefs.emailLinked.stream), isFalse);
    });
  });

  group("secure your app", () {
    Credential emailCard(String hash, String address) => Credential(
      credentialId: "pbdf.sidn-pbdf.email",
      hash: hash,
      name: "Email address",
      issuer: _requestor,
      credentialInstanceIds: const {},
      batchInstanceCountsRemaining: const {},
      attributes: [
        Attribute(
          claimPath: ["email"],
          displayName: "Email address",
          value: AttributeValue(type: AttributeType.string, string: address),
        ),
      ],
      revoked: false,
      revocationSupported: false,
      issueUrl: null,
    );

    Future<void> pumpSecure(
      WidgetTester tester,
      List<Credential> cards, {
      List<Override> overrides = const [],
    }) async {
      await pumpApp(
        tester,
        overrides: [
          credentialsProvider.overrideWith(
            (ref) => Stream.value((
              credentials: cards,
              problematic: const <ProblematicCredential>[],
            )),
          ),
          ...overrides,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const Key("secure"),
              onPressed: () => secureApp(context),
              child: const Text("secure"),
            ),
          ),
        ),
      );
      await settle(tester);
      // As on the Data tab, which watches the cards.
      final cardsLoaded = container.listen(credentialsProvider, (_, _) {});
      addTearDown(cardsLoaded.close);
      await settle(tester);
      await tester.tap(find.byKey(const Key("secure")));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await settle(tester);
      }
    }

    testWidgets("without an e-mail card: the e-mail card's flow, from the "
        "address", (tester) async {
      linkingOffered = true;
      await pumpSecure(tester, const []);
      expect(sheet, findsOneWidget);
      expect(find.text("Link your email address"), findsOneWidget);
      expect(find.byKey(const Key("secure_app_sheet")), findsNothing);
    });

    testWidgets("with one: use that address, no new code", (tester) async {
      linkingOffered = true;
      await pumpSecure(tester, [emailCard("h1", "sanne@devries.example")]);
      expect(find.byKey(const Key("secure_app_sheet")), findsOneWidget);
      expect(find.text("Use your email address?"), findsOneWidget);
      expect(find.text("sanne@devries.example"), findsOneWidget);

      await tester.tap(find.byKey(const Key("secure_app_use")).last);
      await settle(tester);
      await settle(tester);
      expect(find.byKey(const Key("secure_app_sheet")), findsNothing);
      // The keyshare disclosure, not a new e-mail issuance.
      expect(linkApi.calls, 1);
      expect(issuerApi.sent, isEmpty);
    });

    testWidgets("with two: pick one; or use another address", (tester) async {
      linkingOffered = true;
      await pumpSecure(tester, [
        emailCard("h1", "sanne@devries.example"),
        emailCard("h2", "sanne@werk.example"),
      ]);
      expect(find.text("Which email address?"), findsOneWidget);
      Matcher picked(bool selected) => isSemantics(isSelected: selected);
      SemanticsNode card(String hash) =>
          tester.getSemantics(find.byKey(Key("secure_app_card_$hash")));
      await tester.tap(find.byKey(const Key("secure_app_card_h2")));
      await tester.pump();
      expect(card("h2"), picked(true));
      expect(card("h1"), picked(false));

      await tester.tap(find.byKey(const Key("secure_app_another")));
      await settle(tester);
      await settle(tester);
      expect(find.byKey(const Key("secure_app_sheet")), findsNothing);
      expect(find.text("Link your email address"), findsOneWidget);
    });

    testWidgets("an e-mail card added in Add data ends on \"Secure your "
        "app with it?\"; Not now just closes", (tester) async {
      linkingOffered = true;
      final card = emailCard("h9", "jan@example.com");
      await pumpApp(
        tester,
        overrides: [
          sessionStateProvider.overrideWith(
            (ref, id) => Stream.value(
              SessionState(
                id: id,
                protocol: "irma",
                type: SessionType.issuance,
                status: SessionStatus.success,
                requestor: _requestor,
                continueOnSecondDevice: true,
                offeredCredentials: [card],
              ),
            ),
          ),
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const Key("add_email"),
              onPressed: () => showAddDataSheet(
                context,
                addNew: CredentialDescriptor(
                  credentialId: "pbdf.sidn-pbdf.email",
                  name: "Email address",
                  issuer: _requestor,
                  category: null,
                  attributes: const [],
                  issueURL: "https://email-issuer.example/issue",
                ),
                flyToDataTab: false,
              ),
              child: const Text("add"),
            ),
          ),
        ),
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key("add_email")));
      await settle(tester);
      await settle(tester);
      // The details say adding it also secures the app.
      expect(find.byKey(const Key("secures_app_chip")), findsOneWidget);
      await tester.tap(find.byKey(const Key("sheet_go_button")).last);
      await settle(tester);
      await sendEmailTo(tester, "jan@example.com");
      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        "ABC123",
      );
      for (var i = 0; i < 4; i++) {
        await settle(tester);
      }
      final add = find.byKey(const Key("sheet_issue_add"));
      if (add.evaluate().isNotEmpty) {
        await tester.tap(add.last);
        for (var i = 0; i < 4; i++) {
          await settle(tester);
        }
      }

      expect(find.byKey(const Key("sheet_success_offer")), findsOneWidget);
      expect(find.text("Secure your app with it?"), findsOneWidget);
      expect(
        find.textContaining("Use jan@example.com to secure your app"),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key("secure_offer_not_now")).last);
      await settle(tester);
      await settle(tester);
      expect(sheet, findsNothing);
      expect(linkApi.calls, 0);
      expect(await stored(tester, prefs.emailLinked.stream), isFalse);
    });

    test("the chosen card is picked on the share screen", () async {
      SelectableCredentialInstance instance(String hash) =>
          SelectableCredentialInstance(
            credentialId: "pbdf.sidn-pbdf.email",
            hash: hash,
            name: "Email address",
            issuer: _requestor,
            format: CredentialFormat.idemix,
            attributes: const [],
            revoked: false,
            revocationSupported: false,
            usable: true,
          );
      final c = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          irmaRepositoryProvider.overrideWithValue(repo),
          sessionStateProvider.overrideWith(
            (ref, id) => Stream.value(
              SessionState(
                id: id,
                protocol: "irma",
                type: SessionType.disclosure,
                status: SessionStatus.requestPermission,
                requestor: _requestor,
                disclosurePlan: DisclosurePlan(
                  choices: [
                    DisclosureChoice(
                      optional: false,
                      options: [
                        DisclosureOption(
                          slots: [
                            DisclosureSlot(
                              id: "email",
                              candidates: [instance("h1"), instance("h2")],
                              obtainable: const [],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      final keep = c.listen(disclosureSelectionProvider(7), (_, _) {});
      addTearDown(keep.close);

      preferCardInSession(c, 7, "h2");
      await pumpEventQueue();

      expect(c.read(disclosureSelectionProvider(7)).cards, {
        "email": ["h2"],
      });
    });
  });
}
