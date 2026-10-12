import "dart:async";

import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:pinput/pinput.dart";
import "package:yivi_core/src/models/email_code_pointer.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/email_issuance_provider.dart";
import "package:yivi_core/src/providers/issue_during_disclosure_provider.dart";
import "package:yivi_core/src/providers/missing_data_flow_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/email/email_issuance_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/missing_data_confirm_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/missing_data_button.dart";

import "missing_data_fixtures.dart";

const _issuanceSessionId = 2;
const _testAddress = "rosanne@voorbeeld.nl";

// Long enough for the code screen to finish animating in.
const _codeScreenSettled = Duration(milliseconds: 800);

enum _EmailEntry { fromChecklist, standalone }

/// An issuer that holds every code check until [release] and then rejects it.
class _SlowIssuerApi implements EmailIssuerApi {
  final _gate = Completer<void>();
  var checks = 0;

  void release() => _gate.complete();

  @override
  Future<void> sendEmail({
    required String emailAddress,
    required String language,
  }) async {}

  @override
  Future<SessionPointer> verifyCode({
    required String email,
    required String verificationCode,
  }) async {
    checks++;
    await _gate.future;
    throw EmailIssuanceInvalidCodeError();
  }
}

Credential _emailCredential() => Credential(
  credentialId: "email",
  hash: "hash-email",
  name: "Cred email",
  issuer: testParty("Yivi"),
  credentialInstanceIds: const {},
  batchInstanceCountsRemaining: const {},
  attributes: [
    Attribute(
      claimPath: ["email"],
      displayName: "E-mailadres",
      value: AttributeValue(type: AttributeType.string, string: _testAddress),
    ),
  ],
  revoked: false,
  revocationSupported: false,
  issueUrl: null,
);

/// The issuance session the user ends up in after obtaining a credential.
SessionState _issuanceSession() => SessionState(
  id: _issuanceSessionId,
  protocol: "irma",
  type: SessionType.issuance,
  status: SessionStatus.requestPermission,
  requestor: testParty("Yivi"),
  offeredCredentials: [_emailCredential()],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final steps = [
    testStep([
      [testDescriptor("email")],
    ]),
    testStep([
      [testDescriptor("phone")],
    ]),
  ];

  void watchSession(MissingDataHarness harness) {
    harness.container.listen(
      issueDuringDisclosureProvider(testSessionId),
      (_, _) {},
    );
  }

  Future<void> collectFor(
    MissingDataHarness harness,
    WidgetTester tester, {
    required String credentialId,
  }) async {
    watchSession(harness);
    await harness.emit(tester, testSession(steps: steps));
    harness.container
        .read(missingDataFlowProvider.notifier)
        .start(sessionId: testSessionId, credentialId: credentialId);
    await tester.pump();
  }

  group("e-mail screens", () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: "/session",
        routes: [
          GoRoute(
            path: "/session",
            builder: (_, _) => const Scaffold(body: Text("session page")),
          ),
          GoRoute(
            path: "/issue_email",
            builder: (_, _) => const EmailIssuanceScreen(),
          ),
        ],
      );
    });

    Future<MissingDataHarness> openEmailScreen(
      WidgetTester tester, {
      required _EmailEntry entry,
      List<Override> overrides = const [],
    }) async {
      final harness = await MissingDataHarness.pump(
        tester,
        router,
        overrides: overrides,
      );
      if (entry == _EmailEntry.fromChecklist) {
        await collectFor(harness, tester, credentialId: "email");
      }
      router.push("/issue_email");
      await tester.pumpAndSettle();
      return harness;
    }

    testWidgets("ask for the address as the design does", (tester) async {
      await openEmailScreen(tester, entry: _EmailEntry.fromChecklist);

      expect(find.text("Cred email ophalen"), findsOneWidget);
      expect(find.text("Wat is je e-mailadres?"), findsOneWidget);
      expect(
        find.text(
          "We sturen je een e-mail met een code. "
          "Daarmee laat je zien dat het jouw e-mailadres is.",
        ),
        findsOneWidget,
      );
      expect(find.text("E-mail versturen"), findsOneWidget);
      expect(find.text("Terug naar de lijst"), findsOneWidget);
      expect(find.text("Voer je e-mailadres in"), findsNothing);
      expect(find.text("E-mailadres toevoegen"), findsNothing);
    });

    testWidgets("keep today's copy outside the checklist", (tester) async {
      await openEmailScreen(tester, entry: _EmailEntry.standalone);

      expect(find.text("E-mailadres toevoegen"), findsOneWidget);
      expect(find.text("Voer je e-mailadres in"), findsOneWidget);
      expect(find.text("Wat is je e-mailadres?"), findsNothing);
    });

    testWidgets("ask for the code with a button, as the design does", (
      tester,
    ) async {
      final harness = await openEmailScreen(
        tester,
        entry: _EmailEntry.fromChecklist,
      );
      harness.container
          .read(emailIssuanceProvider.notifier)
          .startVerification(email: _testAddress);
      await tester.pump(_codeScreenSettled);

      expect(find.text("Cred email ophalen"), findsOneWidget);
      expect(find.text("Vul de code in"), findsOneWidget);
      expect(
        find.text(
          "We hebben een e-mail gestuurd naar $_testAddress. "
          "Vul de code uit de e-mail hier in.",
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text("E-mail opnieuw sturen"), findsOneWidget);
      expect(find.text("Code niet ontvangen?"), findsNothing);

      MissingDataButton check() => tester.widget<MissingDataButton>(
        find.byKey(const Key("bottom_bar_primary")),
      );
      expect(find.text("Code controleren"), findsOneWidget);
      expect(check().onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        "A" * emailCodeLength,
      );
      await tester.pump();

      expect(check().onPressed, isNotNull);
    });

    testWidgets("check the code once when the button is tapped twice", (
      tester,
    ) async {
      final issuer = _SlowIssuerApi();
      final harness = await openEmailScreen(
        tester,
        entry: _EmailEntry.fromChecklist,
        overrides: [emailIssuerApiProvider.overrideWithValue(issuer)],
      );
      harness.container
          .read(emailIssuanceProvider.notifier)
          .startVerification(email: _testAddress);
      await tester.pump(_codeScreenSettled);
      final field = find.byKey(
        const Key("email_verification_code_input_field"),
      );
      final check = find.byKey(const Key("bottom_bar_primary"));
      await tester.enterText(field, "A" * emailCodeLength);
      await tester.pump();

      await tester.tap(check);
      await tester.pump();
      await tester.tap(check);
      await tester.pump();

      expect(issuer.checks, 1);

      // A wrong code clears the field and lets the user try again.
      issuer.release();
      await tester.pump();
      await tester.pump();

      await tester.enterText(field, "B" * emailCodeLength);
      await tester.pump();
      await tester.tap(check);
      await tester.pump();

      expect(issuer.checks, 2);
    });

    testWidgets("draw the code boxes white on the blue page", (tester) async {
      final harness = await openEmailScreen(
        tester,
        entry: _EmailEntry.fromChecklist,
      );
      harness.container
          .read(emailIssuanceProvider.notifier)
          .startVerification(email: _testAddress);
      await tester.pump(_codeScreenSettled);

      final theme = IrmaThemeData();
      final page = tester.widget<Scaffold>(find.byType(Scaffold).last);
      final box = tester
          .widget<Pinput>(
            find.byKey(const Key("email_verification_code_input_field")),
          )
          .defaultPinTheme!
          .decoration!;

      expect(page.backgroundColor, theme.backgroundTertiary);
      expect(box.gradient?.colors.first, theme.light);
      expect(find.text("Code"), findsOneWidget);
    });

    testWidgets("keep today's code screen outside the checklist", (
      tester,
    ) async {
      final harness = await openEmailScreen(
        tester,
        entry: _EmailEntry.standalone,
      );
      harness.container
          .read(emailIssuanceProvider.notifier)
          .startVerification(email: _testAddress);
      await tester.pump(_codeScreenSettled);

      expect(find.text("We hebben je een e-mail gestuurd"), findsOneWidget);
      expect(find.text("Code niet ontvangen?"), findsOneWidget);
      expect(find.text("Code controleren"), findsNothing);
    });
  });

  group("MissingDataButton", () {
    testWidgets("is a button, and a disabled one says so", (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: "/",
            builder: (_, _) => Scaffold(
              body: Column(
                children: [
                  MissingDataButton(
                    label: "missing_data.share",
                    onPressed: () {},
                  ),
                  const MissingDataButton(label: "missing_data.back_to_list"),
                ],
              ),
            ),
          ),
        ],
      );
      await MissingDataHarness.pump(tester, router);
      final semantics = tester.ensureSemantics();

      expect(
        tester.getSemantics(find.text("Delen")),
        isSemantics(
          label: "Delen",
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text("Terug naar de lijst")),
        isSemantics(
          label: "Terug naar de lijst",
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      semantics.dispose();
    });
  });

  group("the step to confirm adding", () {
    late GoRouter router;
    var added = 0;
    var left = 0;

    setUp(() {
      added = 0;
      left = 0;
      router = GoRouter(
        initialLocation: "/session",
        routes: [
          GoRoute(
            path: "/session",
            builder: (_, _) => const Scaffold(body: Text("session page")),
          ),
          GoRoute(
            path: "/confirm",
            builder: (_, _) => MissingDataConfirmScreen(
              issuedCredentials: [_emailCredential()],
              onGivePermission: () => added++,
              onDismiss: () => left++,
            ),
          ),
          GoRoute(
            path: "/issuance",
            builder: (_, _) => const SessionScreen(
              sessionId: _issuanceSessionId,
              hasUnderlyingSession: true,
            ),
          ),
        ],
      );
    });

    testWidgets("shows what is added and where the user goes next", (
      tester,
    ) async {
      final harness = await MissingDataHarness.pump(tester, router);
      await collectFor(harness, tester, credentialId: "email");
      router.push("/confirm");
      await tester.pumpAndSettle();

      expect(find.text("Cred email ophalen"), findsOneWidget);
      expect(
        find.text("Wil je dit gegeven aan je Yivi-app toevoegen?"),
        findsOneWidget,
      );
      expect(find.text("Cred email"), findsOneWidget);
      expect(find.text("Yivi"), findsOneWidget);
      expect(find.text("E-mailadres"), findsOneWidget);
      expect(find.text(_testAddress), findsOneWidget);
      expect(
        find.text("Daarna ga je terug naar de lijst van Test Verifier."),
        findsOneWidget,
      );
      expect(find.text("Toevoegen"), findsOneWidget);
      expect(find.text("Terug naar de lijst"), findsOneWidget);
    });

    testWidgets("adds, or leads back to the list", (tester) async {
      final harness = await MissingDataHarness.pump(tester, router);
      await collectFor(harness, tester, credentialId: "email");
      router.push("/confirm");
      await tester.pumpAndSettle();

      await tester.tap(find.text("Toevoegen"));
      expect(added, 1);

      await tester.tap(find.text("Terug naar de lijst"));
      await tester.tap(find.byKey(const Key("irma_app_bar_leading")));
      expect(left, 2);
    });

    testWidgets("replaces the permission step for a session from the list", (
      tester,
    ) async {
      final harness = await MissingDataHarness.pump(tester, router);
      await collectFor(harness, tester, credentialId: "email");
      router.push("/issuance");
      await tester.pump();
      await harness.emit(tester, _issuanceSession());
      await tester.pumpAndSettle();

      expect(
        find.text("Wil je dit gegeven aan je Yivi-app toevoegen?"),
        findsOneWidget,
      );
      expect(find.text("Gegevens toevoegen"), findsNothing);
    });

    testWidgets("keeps the permission step for other issuance sessions", (
      tester,
    ) async {
      final harness = await MissingDataHarness.pump(tester, router);
      router.push("/issuance");
      await tester.pump();
      await harness.emit(tester, _issuanceSession());
      await tester.pumpAndSettle();

      expect(
        find.text("Wil je deze gegevens aan je Yivi-app toevoegen?"),
        findsOneWidget,
      );
      expect(find.text("Gegevens toevoegen"), findsWidgets);
      expect(find.text("Toevoegen"), findsNothing);
    });
  });
}
