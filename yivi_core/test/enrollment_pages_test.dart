import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/schemaless/session_user_interaction.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_events.dart";
import "package:yivi_core/src/providers/email_issuance_provider.dart";
import "package:yivi_core/src/providers/email_linking_provider.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/back_to_website/back_to_website_screen.dart";
import "package:yivi_core/src/screens/enrollment/biometric/enrollment_biometric_screen.dart";
import "package:yivi_core/src/screens/enrollment/choose_pin/choose_pin_screen.dart";
import "package:yivi_core/src/screens/enrollment/email/enrollment_email_screen.dart";
import "package:yivi_core/src/screens/enrollment/welcome/welcome_screen.dart";
import "package:yivi_core/src/screens/pin/providers/biometric_provider.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";
import "package:yivi_core/src/widgets/glass/pill_buttons.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";

import "support/onboarding_v2_harness.dart";

/// The four sizes of the design, with the safe areas of an iPhone 17 Pro and
/// an 11" iPad.
const _sizes = {
  "phone upright": (Size(390, 844), EdgeInsets.fromLTRB(0, 62, 0, 34)),
  "phone sideways": (Size(844, 390), EdgeInsets.fromLTRB(62, 0, 62, 21)),
  "tablet upright": (Size(820, 1180), EdgeInsets.fromLTRB(0, 24, 0, 20)),
  "tablet sideways": (Size(1180, 820), EdgeInsets.fromLTRB(0, 24, 0, 20)),
};

void _device(WidgetTester tester, Size size, EdgeInsets padding) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = FakeViewPadding(
    left: padding.left,
    top: padding.top,
    right: padding.right,
    bottom: padding.bottom,
  );
  addTearDown(tester.view.reset);
}

class _FakeEmailIssuerApi implements EmailIssuerApi {
  final sent = <String>[];
  var codeRight = true;

  @override
  Future<void> sendEmail({
    required String emailAddress,
    required String language,
  }) async => sent.add(emailAddress);

  @override
  Future<SessionPointer> verifyCode({
    required String email,
    required String verificationCode,
  }) async {
    if (!codeRight) throw EmailIssuanceInvalidCodeError();
    return SessionPointer(
      u: "https://email-issuer.example/session",
      irmaqr: "issuing",
      protocol: Protocol.irma,
    );
  }
}

class _FakeLinkApi implements KeyshareEmailLinkApi {
  var calls = 0;

  @override
  Future<SessionPointer> startSession() async {
    calls++;
    return SessionPointer(
      u: "https://keyshare.example/session",
      irmaqr: "disclosing",
      protocol: Protocol.irma,
    );
  }
}

SessionStateEvent _state(int id, SessionStatus status) => SessionStateEvent(
  sessionState: SessionState(
    id: id,
    protocol: "irma",
    type: SessionType.issuance,
    status: status,
    requestor: TrustedParty(
      id: "yivi",
      name: "Yivi",
      url: null,
      parent: null,
      verified: true,
    ),
  ),
);

void main() {
  late RecordingBridge bridge;
  late IrmaRepository repo;

  setUp(() async {
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  group("welcome", () {
    for (final MapEntry(key: name, value: (size, padding)) in _sizes.entries) {
      testWidgets("$name: the cards, the title, and Get started after the "
          "terms", (tester) async {
        _device(tester, size, padding);
        var accepted = false;
        var started = 0;
        Future<void> pump() => pumpHome(
          tester,
          repo: repo,
          home: StatefulBuilder(
            builder: (context, setState) => WelcomeScreen(
              isAccepted: accepted,
              onToggleAccepted: (v) => setState(() => accepted = v),
              onContinue: () => started++,
            ),
          ),
        );
        await pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(CredentialCardArt), findsNWidgets(3));
        expect(
          find.text("Your digital identity, safe on your phone"),
          findsOneWidget,
        );
        expect(find.text("Only on your phone"), findsOneWidget);

        final start = find.byKey(const Key("enrollment_next_button"));
        expect(tester.widget<FancyPillButton>(start).onPressed, isNull);

        // A small phone with large text scrolls the page down to the terms.
        await tester.runAsync(
          () => Scrollable.ensureVisible(
            tester.element(find.byKey(const Key("accept_terms_checkbox"))),
            alignment: 0.5,
          ),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key("accept_terms_checkbox")));
        await tester.pump();
        expect(tester.widget<FancyPillButton>(start).onPressed, isNotNull);
        await tester.tap(start);
        expect(started, 1);
      });
    }
  });

  group("PIN", () {
    for (final name in [
      "tablet sideways",
      "phone sideways",
      "tablet upright",
    ]) {
      testWidgets("$name: the keypad beside the title only when sideways", (
        tester,
      ) async {
        final (size, padding) = _sizes[name]!;
        _device(tester, size, padding);
        await pumpHome(
          tester,
          repo: repo,
          home: ChoosePinScreen(
            stepLabel: "Step 1 of 3",
            onChoosePin: (_) {},
            onPrevious: () {},
            newPinNotifier: ValueNotifier(""),
          ),
        );
        // The long-PIN preference streams in.
        await settle(tester);

        final title = tester.getRect(find.textContaining("Choose a"));
        final key = tester.getRect(find.text("1"));
        if (size.width > size.height) {
          expect(key.left, greaterThan(title.right));
        } else {
          expect(key.top, greaterThan(title.bottom));
        }
        expect(find.text("Step 1 of 3"), findsOneWidget);
      });
    }
  });

  group("Face ID", () {
    for (final MapEntry(key: name, value: (size, padding)) in _sizes.entries) {
      testWidgets("$name: Not now declines and goes on", (tester) async {
        _device(tester, size, padding);
        var done = 0;
        await pumpHome(
          tester,
          repo: repo,
          overrides: [biometricTypeProvider.overrideWith((ref) async => null)],
          home: EnrollmentBiometricScreen(
            stepLabel: "Step 2 of 3",
            onDone: () => done++,
          ),
        );
        await tester.pump();

        expect(find.text("Step 2 of 3"), findsOneWidget);
        expect(find.text("Open Yivi with your fingerprint?"), findsOneWidget);
        await tester.tap(find.byKey(const Key("biometric_not_now")));
        await settle(tester);

        expect(done, 1);
        expect(
          await tester.runAsync(
            () => repo.preferences.getBiometricPromptDismissed().first,
          ),
          isTrue,
        );
      });
    }
  });

  group("e-mail step", () {
    late _FakeEmailIssuerApi issuer;
    late _FakeLinkApi link;
    late Completer<SessionError?> account;
    late int done;

    setUp(() {
      issuer = _FakeEmailIssuerApi();
      link = _FakeLinkApi();
      account = Completer();
      done = 0;
    });

    Future<void> pumpStep(WidgetTester tester) async {
      await pumpHome(
        tester,
        repo: repo,
        overrides: [
          irmaRepositoryProvider.overrideWithValue(repo),
          emailIssuerApiProvider.overrideWithValue(issuer),
          keyshareEmailLinkApiProvider.overrideWithValue(link),
        ],
        // The code field needs the core Material the app root gives.
        home: LegacyMaterialBridge(
          child: EnrollmentEmailScreen(
            stepLabel: "Step 3 of 3 · optional",
            account: () => account.future,
            pin: "12345",
            onDone: () => done++,
            onAccountFailed: (_) {},
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> enterAddress(WidgetTester tester) async {
      await tester.enterText(
        find.byKey(const Key("email_input_field")),
        "jan@example.com",
      );
      await tester.pump();
    }

    /// irmago: every session asks for permission, then the PIN, and works.
    void irmago() {
      bridge.respond = (Event event) {
        if (event is NewSessionEvent) {
          return _state(event.sessionId, SessionStatus.requestPermission);
        }
        if (event is SessionUserInteractionEvent) {
          return _state(
            event.sessionId,
            event.type == UserInteractionType.permission
                ? SessionStatus.requestPin
                : SessionStatus.success,
          );
        }
        return null;
      };
    }

    for (final MapEntry(key: name, value: (size, padding)) in _sizes.entries) {
      testWidgets("$name: address, then the code, then linked", (tester) async {
        _device(tester, size, padding);
        irmago();
        await pumpStep(tester);

        expect(find.text("Link your email address?"), findsOneWidget);
        expect(find.byKey(const Key("enrollment_email_skip")), findsOneWidget);

        await enterAddress(tester);
        await tester.ensureVisible(
          find.byKey(const Key("enrollment_email_send")),
        );
        await tester.tap(find.byKey(const Key("enrollment_email_send")));
        await tester.pump();
        // The code goes out once the account is there.
        expect(issuer.sent, isEmpty);
        account.complete(null);
        await settle(tester);

        expect(issuer.sent, ["jan@example.com"]);
        expect(find.text("Check your email"), findsOneWidget);
        expect(find.text("jan@example.com"), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key("email_verification_code_input_field")),
          "ABC123",
        );
        for (var i = 0; i < 10; i++) {
          await settle(tester);
        }

        expect(link.calls, 1);
        final pins = bridge.dispatched
            .whereType<SessionUserInteractionEvent>()
            .where((e) => e.type == UserInteractionType.enteredPin);
        // The issuance and the link in MijnYivi, both with this PIN.
        expect(pins.map((e) => e.payload!["pin"]), ["12345", "12345"]);
        expect(
          await tester.runAsync(() => repo.preferences.getEmailLinked().first),
          isTrue,
        );
        expect(
          find.byKey(const Key("enrollment_email_linked")),
          findsOneWidget,
        );

        await tester.pump(const Duration(milliseconds: 1300));
        expect(done, 1);
      });
    }

    testWidgets("Skip goes on without an address", (tester) async {
      _device(tester, _sizes["phone upright"]!.$1, _sizes["phone upright"]!.$2);
      await pumpStep(tester);

      await tester.tap(find.byKey(const Key("enrollment_email_skip")));
      await tester.pump();
      expect(done, 1);
      expect(issuer.sent, isEmpty);
    });

    testWidgets("a wrong code says so and keeps the step", (tester) async {
      _device(tester, _sizes["phone upright"]!.$1, _sizes["phone upright"]!.$2);
      account.complete(null);
      issuer.codeRight = false;
      await pumpStep(tester);
      await enterAddress(tester);
      await tester.tap(find.byKey(const Key("enrollment_email_send")));
      await settle(tester);

      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        "ABC123",
      );
      await settle(tester);

      expect(
        find.text("That code is not right. Check it, or send a new one."),
        findsOneWidget,
      );
      expect(link.calls, 0);
      expect(done, 0);
    });

    testWidgets("phone sideways with the keyboard: Send code next to the "
        "field, without the tile and the step", (tester) async {
      final (size, padding) = _sizes["phone sideways"]!;
      _device(tester, size, padding);
      tester.view.viewInsets = const FakeViewPadding(bottom: 196);
      // Without the harness's Scaffold, which would take the keyboard off.
      await pumpRoutes(
        tester,
        repo: repo,
        overrides: [irmaRepositoryProvider.overrideWithValue(repo)],
        initialLocation: "/",
        routes: [
          GoRoute(
            path: "/",
            builder: (_, _) => LegacyMaterialBridge(
              child: EnrollmentEmailScreen(
                stepLabel: "Step 3 of 3 · optional",
                account: () => account.future,
                pin: "12345",
                onDone: () => done++,
                onAccountFailed: (_) {},
              ),
            ),
          ),
        ],
      );
      await tester.pump();

      expect(find.text("Step 3 of 3 · optional"), findsNothing);
      expect(find.byIcon(Icons.mail_rounded), findsNothing);
      final field = tester.getRect(find.byKey(const Key("email_input_field")));
      final send = tester.getRect(
        find.byKey(const Key("enrollment_email_send")),
      );
      expect(send.center.dy, closeTo(field.center.dy, 4));
      expect(send.left, greaterThan(field.right));
    });
  });

  group("back to the website", () {
    for (final MapEntry(key: name, value: (size, padding)) in _sizes.entries) {
      testWidgets("$name: the steps and a close button", (tester) async {
        _device(tester, size, padding);
        await pumpHome(tester, repo: repo, home: const BackToWebsiteScreen());
        await tester.pump();

        expect(find.text("Go back to the website"), findsOneWidget);
        expect(
          find.text(
            "Switch back to your browser, to the website that asked for Yivi.",
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key("back_to_website_close")), findsOneWidget);
      });
    }
  });
}
