import "dart:async";

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
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/credential_store.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/handle_url_event.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_state.dart";
import "package:yivi_core/src/providers/contact_issuance_provider.dart";
import "package:yivi_core/src/providers/credentials_provider.dart";
import "package:yivi_core/src/providers/email_linking_provider.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/session_launcher.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/routing/navigation.dart";
import "package:yivi_core/src/screens/add_data/email_linking.dart";
import "package:yivi_core/src/screens/data/widgets/email_link_banner.dart";
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
      child: IrmaTheme(
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

  group("banner", () {
    Future<void> pumpBanner(
      WidgetTester tester, {
      bool hasCredentials = true,
    }) async {
      await pumpApp(
        tester,
        overrides: [hasCredentialsProvider.overrideWithValue(hasCredentials)],
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ref.watch(emailBannerVisibleProvider)
                ? const EmailLinkBanner()
                : const Text("no banner"),
          ),
        ),
      );
      await settle(tester);
    }

    testWidgets("shows the copy of the design when linking is offered", (
      tester,
    ) async {
      linkingOffered = true;
      await pumpBanner(tester);

      expect(find.text("Secure your Yivi app"), findsOneWidget);
      expect(
        find.text(
          "Link your email address. Then you can block your app if you lose your phone.",
        ),
        findsOneWidget,
      );
      expect(find.text("Link email address"), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets("waits for the first credential, so it is not there right "
        "after enrollment", (tester) async {
      linkingOffered = true;
      await pumpBanner(tester, hasCredentials: false);

      expect(find.byType(EmailLinkBanner), findsNothing);
    });

    testWidgets("is absent when linking is not offered", (tester) async {
      await pumpBanner(tester);

      expect(find.byType(EmailLinkBanner), findsNothing);
      expect(find.text("no banner"), findsOneWidget);
    });

    testWidgets(
      "the close button opens the sheet, and closing it keeps the banner",
      (tester) async {
        linkingOffered = true;
        await pumpBanner(tester);

        await tester.tap(find.byKey(const Key("email_link_banner_close")));
        await tester.pumpAndSettle();

        expect(find.text("Remind you later?"), findsOneWidget);
        expect(
          find.textContaining("Without a linked email address"),
          findsOneWidget,
        );
        expect(find.text("Ask me later"), findsOneWidget);
        expect(find.text("Dismiss"), findsOneWidget);
        // Kept on the page under the sheet (not drawn while it is open).
        expect(
          find.byType(EmailLinkBanner, skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets("Ask me later hides the banner for now", (tester) async {
      linkingOffered = true;
      await pumpBanner(tester);

      await tester.tap(find.byKey(const Key("email_link_banner_close")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("email_link_later_remind")));
      await settle(tester);
      await tester.pumpAndSettle();

      expect(find.byType(EmailLinkBanner), findsNothing);
      expect(find.text("Remind you later?"), findsNothing);
      expect(await stored(tester, prefs.emailBannerDismissed.stream), isFalse);
      expect(
        (await stored(
          tester,
          prefs.emailBannerSnoozedUntil.stream,
        ))!.isAfter(DateTime.now().add(const Duration(days: 1))),
        isTrue,
      );

      // The timer that ends the snooze only stops with its container, and the
      // test checks for pending timers before the tear-down runs.
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets("Dismiss hides the banner for good", (tester) async {
      linkingOffered = true;
      await pumpBanner(tester);

      await tester.tap(find.byKey(const Key("email_link_banner_close")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("email_link_later_dismiss")));
      await settle(tester);
      await tester.pumpAndSettle();

      expect(find.byType(EmailLinkBanner), findsNothing);
      expect(await stored(tester, prefs.emailBannerDismissed.stream), isTrue);
    });

    testWidgets("the link opens the e-mail flow for linking", (tester) async {
      linkingOffered = true;
      await pumpBanner(tester);
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
      await settle(tester);

      await tester.tap(find.text("Link email address"));
      await settle(tester);
      await tester.pumpAndSettle();

      expect(sheet, findsOneWidget);
      expect(find.text("Link your email address"), findsOneWidget);
      expect(
        container.read(emailIssuerUrlProvider),
        "https://email-issuer.example",
      );
    });
  });
}
