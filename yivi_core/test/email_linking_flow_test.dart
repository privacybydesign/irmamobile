import "dart:async";

import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:pinput/pinput.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/email_code_pointer.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/handle_url_event.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/email_issuance_provider.dart";
import "package:yivi_core/src/providers/email_linking_provider.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/data/widgets/email_link_banner.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/email/email_issuance_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/handle_pointer.dart";
import "package:yivi_core/src/util/navigation.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";

class _SilentBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

class _FakeEmailIssuerApi implements EmailIssuerApi {
  final sent = <String>[];
  final verified = <({String email, String code})>[];

  @override
  Future<void> sendEmail({
    required String emailAddress,
    required String language,
  }) async {
    sent.add(emailAddress);
  }

  @override
  Future<SessionPointer> verifyCode({
    required String email,
    required String verificationCode,
  }) async {
    verified.add((email: email, code: verificationCode));
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IrmaPreferences prefs;
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
  });

  // Mirrors the routes the flow uses in routing.dart: the real router builds
  // the whole home screen, which needs far more setup than this test.
  Future<void> pumpApp(
    WidgetTester tester, {
    Widget? home,
    List<Override> overrides = const [],
  }) async {
    container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        irmaRepositoryProvider.overrideWithValue(repo),
        emailIssuerApiProvider.overrideWithValue(issuerApi),
        keyshareEmailLinkApiProvider.overrideWithValue(linkApi),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);

    router = GoRouter(
      initialLocation: "/home",
      routes: [
        GoRoute(
          path: "/home",
          builder: (context, state) =>
              home ?? const Scaffold(body: Text("home")),
        ),
        GoRoute(
          path: "/issue_email",
          builder: (context, state) {
            return EmailIssuanceScreen(
              purpose:
                  state.extra as EmailIssuancePurpose? ??
                  EmailIssuancePurpose.addCredential,
            );
          },
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

    final widget = UncontrolledProviderScope(
      container: container,
      child: IrmaRepositoryProvider(
        repository: repo,
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
      ),
    );

    // FileTranslationLoader reads the locale JSON with real IO, which the test
    // framework's fake clock does not drive.
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
  }

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
    router.push("/issue_email", extra: EmailIssuancePurpose.linkKeyshare);
    await tester.pumpAndSettle();
  }

  Future<void> sendEmailTo(WidgetTester tester, String address) async {
    await tester.enterText(find.byKey(const Key("email_input_field")), address);
    await tester.pump();
    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await settle(tester);
  }

  group("code link in the e-mail", () {
    test("is queued as a pointer with the flag on", () async {
      await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);

      repo.dispatch(
        HandleURLEvent(
          url:
              "https://open.yivi.app/-/email#code=ABC123&email=jan%40example.com",
        ),
      );
      final pointer = await repo
          .getPendingPointer()
          .firstWhere((p) => p != null)
          .timeout(const Duration(seconds: 2));

      expect(pointer, isA<EmailCodePointer>());
      expect((pointer as EmailCodePointer).code, "ABC123");
      expect(pointer.email, "jan@example.com");
    });

    test("is treated as an unknown URL with the flag off", () async {
      repo.dispatch(
        HandleURLEvent(
          url:
              "https://open.yivi.app/-/email#code=ABC123&email=jan%40example.com",
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(repo.pendingPointer, isNull);
    });
  });

  group("enter e-mail and code screens", () {
    testWidgets("link purpose uses the linking copy and a label in the field", (
      tester,
    ) async {
      await pumpApp(tester);
      await openLinkingFlow(tester);

      expect(find.text("Link your email address"), findsOneWidget);
      expect(
        find.textContaining("Then you can block your Yivi app"),
        findsOneWidget,
      );
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key("email_input_field")),
          matching: find.byType(TextField),
        ),
      );
      expect(field.decoration!.labelText, "Email address");
      expect(field.decoration!.hint, isNull);
    });

    testWidgets("adding the credential keeps today's copy and hint", (
      tester,
    ) async {
      await pumpApp(tester);
      router.push("/issue_email");
      await tester.pumpAndSettle();

      expect(find.text("Enter your email address"), findsOneWidget);
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key("email_input_field")),
          matching: find.byType(TextField),
        ),
      );
      expect(field.decoration!.labelText, isNull);
      expect(field.decoration!.hint, isNotNull);
    });

    testWidgets("sending the address opens the code screen", (tester) async {
      await pumpApp(tester);
      await openLinkingFlow(tester);

      await sendEmailTo(tester, "jan@example.com");

      expect(issuerApi.sent, ["jan@example.com"]);
      expect(find.text("Enter the code"), findsOneWidget);
      expect(
        find.textContaining("We've sent an email to jan@example.com"),
        findsOneWidget,
      );
      expect(find.text("Send email again"), findsOneWidget);
    });

    testWidgets("Check code waits for six characters and does not auto-send", (
      tester,
    ) async {
      await pumpApp(tester);
      await openLinkingFlow(tester);
      await sendEmailTo(tester, "jan@example.com");

      Finder checkButton() => find.byKey(const Key("bottom_bar_primary"));
      bool enabled() =>
          tester
              .widget<InkWell>(
                find.descendant(
                  of: checkButton(),
                  matching: find.byType(InkWell),
                ),
              )
              .onTap !=
          null;

      expect(enabled(), isFalse);

      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        "abc12",
      );
      await tester.pump();
      expect(enabled(), isFalse);

      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        "abc123",
      );
      await tester.pump();
      expect(issuerApi.verified, isEmpty);
      expect(enabled(), isTrue);

      await tester.tap(checkButton());
      await settle(tester);

      expect(issuerApi.verified, [(email: "jan@example.com", code: "ABC123")]);
    });

    testWidgets("the issuance session is tracked for the hand-over", (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          // A session that has not reported yet, so it stays on its screen.
          sessionStateProvider.overrideWith(
            (ref, id) => StreamController<SessionState>().stream,
          ),
        ],
      );
      await openLinkingFlow(tester);
      await sendEmailTo(tester, "jan@example.com");
      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        "ABC123",
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key("bottom_bar_primary")));
      await settle(tester);

      expect(openSessions(tester), [1]);
      expect(container.read(emailLinkingProvider).issuanceSessionId, 1);
    });

    testWidgets(
      "adding the credential still sends the code on the sixth character",
      (tester) async {
        await pumpApp(tester);
        router.push("/issue_email");
        await tester.pumpAndSettle();
        await sendEmailTo(tester, "jan@example.com");

        await tester.enterText(
          find.byKey(const Key("email_verification_code_input_field")),
          "ABC123",
        );
        await settle(tester);

        expect(issuerApi.verified, [
          (email: "jan@example.com", code: "ABC123"),
        ]);
        expect(container.read(emailLinkingProvider).issuanceSessionId, isNull);
      },
    );
  });

  group("link while the flow is open", () {
    testWidgets("fills in the code, says so, and continues on its own", (
      tester,
    ) async {
      await pumpApp(tester);
      await openLinkingFlow(tester);
      await sendEmailTo(tester, "jan@example.com");

      container
          .read(emailLinkingProvider.notifier)
          .receiveLink(
            EmailCodePointer(email: "jan@example.com", code: "XYZ789"),
          );
      await settle(tester);

      expect(find.byKey(const Key("code_filled_from_link")), findsOneWidget);
      expect(find.text("Code filled in from the link"), findsOneWidget);
      expect(
        tester
            .widget<Pinput>(
              find.byKey(const Key("email_verification_code_input_field")),
            )
            .controller!
            .text,
        "XYZ789",
      );
      expect(issuerApi.verified, [(email: "jan@example.com", code: "XYZ789")]);
      expect(container.read(emailLinkingProvider).link, isNull);
    });

    testWidgets("opens the linking screens when they are not open yet", (
      tester,
    ) async {
      await pumpApp(tester);
      final context = tester.element(find.text("home"));

      handlePointer(
        context,
        EmailCodePointer(email: "jan@example.com", code: "XYZ789"),
      );
      await settle(tester);
      await settle(tester);

      expect(find.byType(EmailIssuanceScreen), findsOneWidget);
      expect(find.text("Enter the code"), findsOneWidget);
      expect(
        find.textContaining("We've sent an email to jan@example.com"),
        findsOneWidget,
      );
      expect(issuerApi.sent, isEmpty);
      expect(issuerApi.verified, [(email: "jan@example.com", code: "XYZ789")]);
    });

    testWidgets("is applied once when the flow is already open", (
      tester,
    ) async {
      await pumpApp(tester);
      await openLinkingFlow(tester);
      await sendEmailTo(tester, "jan@example.com");
      final context = tester.element(find.text("Enter the code"));

      handlePointer(
        context,
        EmailCodePointer(email: "jan@example.com", code: "XYZ789"),
      );
      await settle(tester);

      expect(find.byType(EmailIssuanceScreen), findsOneWidget);
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
                sessionId == 100
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

    testWidgets("a tracked issuance continues with the keyshare disclosure", (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          sessionStateProvider.overrideWith(
            (ref, sessionId) => sessionId == 100
                ? Stream.value(_successState(sessionId, SessionType.issuance))
                // Go answers after the screen has been pushed, not within it.
                : Stream.fromFuture(
                    Future.delayed(
                      const Duration(milliseconds: 50),
                      () => _successState(sessionId, SessionType.disclosure),
                    ),
                  ),
          ),
        ],
      );
      container.read(emailLinkingProvider.notifier).trackIssuance(100);

      router.push("/session?session_id=100");
      await tester.pump();
      await settle(tester);
      await settle(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(linkApi.calls, 1);
      expect(
        find.text("The data has been successfully added to Yivi"),
        findsNothing,
      );
      expect(openSessions(tester), [1]);
      expect(container.read(emailLinkingProvider).disclosureSessionId, 1);
      expect(find.text("Email address linked"), findsOneWidget);
      expect(await stored(tester, prefs.getEmailLinked()), isTrue);
    });

    testWidgets("an issuance that is not part of the flow ends as today", (
      tester,
    ) async {
      await pumpSession(tester, 100);

      expect(linkApi.calls, 0);
      expect(
        find.text("The data has been successfully added to Yivi"),
        findsOneWidget,
      );
      expect(await stored(tester, prefs.getEmailLinked()), isFalse);
    });

    testWidgets("a disclosure that is not part of the flow links nothing", (
      tester,
    ) async {
      await pumpSession(tester, 5);

      expect(find.text("Email address linked"), findsNothing);
      expect(await stored(tester, prefs.getEmailLinked()), isFalse);
    });

    testWidgets("an unreachable keyshare server ends on the error screen", (
      tester,
    ) async {
      linkApi.failWith = KeyshareEmailLinkUnavailable();
      await pumpApp(
        tester,
        overrides: [
          sessionStateProvider.overrideWith(
            (ref, sessionId) =>
                Stream.value(_successState(sessionId, SessionType.issuance)),
          ),
        ],
      );
      container.read(emailLinkingProvider.notifier).trackIssuance(100);

      router.push("/session?session_id=100");
      await tester.pump();
      await settle(tester);
      await settle(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.textContaining("error linking e-mail address"),
        findsOneWidget,
      );
      expect(openSessions(tester), isEmpty);
      expect(await stored(tester, prefs.getEmailLinked()), isFalse);
    });
  });

  group("banner", () {
    Future<void> pumpBanner(WidgetTester tester) async {
      await pumpApp(
        tester,
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

    testWidgets("shows the copy of the design with the flag on", (
      tester,
    ) async {
      await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
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

    testWidgets("is absent with the flag off", (tester) async {
      await pumpBanner(tester);

      expect(find.byType(EmailLinkBanner), findsNothing);
      expect(find.text("no banner"), findsOneWidget);
    });

    testWidgets(
      "the close button opens the sheet, and closing it keeps the banner",
      (tester) async {
        await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
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
        expect(find.byType(EmailLinkBanner), findsOneWidget);
      },
    );

    testWidgets("Ask me later hides the banner for now", (tester) async {
      await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
      await pumpBanner(tester);

      await tester.tap(find.byKey(const Key("email_link_banner_close")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("email_link_later_remind")));
      await settle(tester);
      await tester.pumpAndSettle();

      expect(find.byType(EmailLinkBanner), findsNothing);
      expect(find.text("Remind you later?"), findsNothing);
      expect(await stored(tester, prefs.getEmailBannerDismissed()), isFalse);
      expect(
        (await stored(
          tester,
          prefs.getEmailBannerSnoozedUntil(),
        ))!.isAfter(DateTime.now().add(const Duration(days: 1))),
        isTrue,
      );
    });

    testWidgets("Dismiss hides the banner for good", (tester) async {
      await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
      await pumpBanner(tester);

      await tester.tap(find.byKey(const Key("email_link_banner_close")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("email_link_later_dismiss")));
      await settle(tester);
      await tester.pumpAndSettle();

      expect(find.byType(EmailLinkBanner), findsNothing);
      expect(await stored(tester, prefs.getEmailBannerDismissed()), isTrue);
    });

    testWidgets("the link opens the e-mail flow for linking", (tester) async {
      await prefs.setFeatureFlag(FeatureFlag.emailLinking, true);
      await pumpBanner(tester);
      repo.dispatch(
        SchemalessCredentialStoreEvent(
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

      expect(find.byType(EmailIssuanceScreen), findsOneWidget);
      expect(find.text("Link your email address"), findsOneWidget);
      expect(
        container.read(emailIssuerUrlProvider),
        "https://email-issuer.example",
      );
    });
  });
}
