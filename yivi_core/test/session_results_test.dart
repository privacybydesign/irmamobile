import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/session/call_info_screen.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_feedback_screen.dart";
import "package:yivi_core/src/screens/session/widgets/done_flight.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";
import "package:yivi_core/src/screens/session/widgets/pairing_required.dart";
import "package:yivi_core/src/screens/session/widgets/requestor_card.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/card_pile.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/credential_card_art.dart";

import "missing_data_fixtures.dart";
import "support/pump_translated.dart";

// The screens at the end of a session: cards added (also inside a
// request), shared, the call screen and the pairing code.

class _SilentBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

/// The big cards of the done screen's pile (the small ones are 58 wide).
final _bigCards = find.byWidgetPredicate(
  (w) => w is CredentialCardArt && w.width == 260,
);

/// The small cards on the logo's corner at the end.
Finder _smallCards() => find.descendant(
  of: find.byKey(const Key("share_done_minis")),
  matching: find.byType(CredentialCardArt),
);

/// The repository and preferences a whole [SessionScreen] needs.
Future<List<Override>> _app() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await IrmaPreferences.fromInstance(
    mostRecentTermsUrlNl: "",
    mostRecentTermsUrlEn: "",
  );
  final repo = IrmaRepository(client: _SilentBridge(), preferences: prefs);
  addTearDown(repo.close);
  return [
    preferencesProvider.overrideWithValue(prefs),
    irmaRepositoryProvider.overrideWithValue(repo),
  ];
}

class _EmptyWallet extends SchemalessCredentialOrderController {
  @override
  Future<List<Credential>> build() async => const [];
}

Attribute _value(String path, String name, String value) => Attribute(
  claimPath: [path],
  displayName: name,
  value: AttributeValue(type: AttributeType.string, string: value),
);

SelectableCredentialInstance _shared(
  String id,
  String name, {
  int? left,
  List<Attribute> attributes = const [],
}) => SelectableCredentialInstance(
  credentialId: id,
  hash: "hash-$id",
  name: name,
  issuer: testParty("Yivi"),
  format: CredentialFormat.idemix,
  attributes: attributes,
  revoked: false,
  revocationSupported: false,
  batchInstanceCountRemaining: left,
);

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
  bool settle = true,
}) async {
  await pumpTranslated(
    tester,
    ProviderScope(
      overrides: [
        schemalessCredentialOrderControllerProvider.overrideWith(
          _EmptyWallet.new,
        ),
        ...overrides,
      ],
      child: IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: const Locale("en", "US"),
              ),
            ),
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: home,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  group("cards added", () {
    testWidgets("one card on its own: its name, and OK", (tester) async {
      await _pump(
        tester,
        IssuanceSuccessScreen(
          credentials: [testCredential("email")],
          onDismiss: (_) {},
        ),
      );

      expect(find.text("Cred email has been added to Yivi."), findsOneWidget);
      expect(find.byKey(const Key("received_check")), findsOneWidget);
      expect(find.byType(CardPile), findsNothing);
      expect(find.text("OK"), findsOneWidget);
    });

    testWidgets("several cards: the pile with one check", (tester) async {
      await _pump(
        tester,
        IssuanceSuccessScreen(
          credentials: [testCredential("a"), testCredential("b")],
          onDismiss: (_) {},
        ),
      );

      expect(find.byType(CardPile), findsOneWidget);
      expect(find.byKey(const Key("received_check")), findsOneWidget);
      expect(
        find.text("These 2 cards have been added to Yivi."),
        findsOneWidget,
      );
    });

    testWidgets("sideways beside a side panel: the pile and its check stay "
        "in the panel", (tester) async {
      // An iPhone Duo unfolded, held sideways: the control bar at the right.
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(951, 669)
        ..padding = const FakeViewPadding(right: 84, bottom: 34);
      addTearDown(tester.view.reset);
      await _pump(
        tester,
        IssuanceSuccessScreen(
          credentials: [testCredential("a"), testCredential("b")],
          onDismiss: (_) {},
        ),
      );

      final panel = tester.getRect(find.byKey(const Key("issuance_panel")));
      final check = tester.getRect(find.byKey(const Key("received_check")));
      expect(check.right, lessThanOrEqualTo(panel.right));
      // On the corner of the front card, as on a single card.
      final front = tester.getRect(
        find
            .descendant(
              of: find.byType(CardPile),
              matching: find.byType(CredentialCardArt),
            )
            .last,
      );
      expect(check.center.dx, moreOrLessEquals(front.right - 14, epsilon: 8));
      expect(check.center.dy, moreOrLessEquals(front.top + 10, epsilon: 8));
    });

    testWidgets("inside a request: next comes the request", (tester) async {
      var dismissed = 0;
      await _pump(
        tester,
        IssuanceSuccessScreen(
          credentials: [testCredential("email")],
          backTo: "Webshop",
          onDismiss: (_) => dismissed++,
        ),
      );

      expect(
        find.text(
          "The card is now in your app. Go back to Webshop to continue.",
        ),
        findsOneWidget,
      );
      await tester.tap(find.text("Back to Webshop"));
      expect(dismissed, 1);
    });

    testWidgets("a nested session shows it, with its request's requestor", (
      tester,
    ) async {
      const nestedId = 2;
      await _pump(
        tester,
        const SessionScreen(sessionId: nestedId, hasUnderlyingSession: true),
        overrides: [
          ...(await tester.runAsync(_app))!,
          sessionStateProvider(nestedId).overrideWith(
            (ref) => Stream.value(
              SessionState(
                id: nestedId,
                protocol: "irma",
                type: SessionType.issuance,
                status: SessionStatus.success,
                requestor: testParty("Issuer"),
                offeredCredentials: [testCredential("email")],
              ),
            ),
          ),
          underlyingDisclosureProvider(
            nestedId,
          ).overrideWith((ref) => Stream.value(testSession(steps: const []))),
        ],
      );

      expect(find.byType(IssuanceSuccessScreen), findsOneWidget);
      expect(find.text("Back to Test Verifier"), findsOneWidget);
    });
  });

  group("shared", () {
    Future<void> pump(
      WidgetTester tester, {
      List<SelectableCredentialInstance> shared = const [],
      bool signature = false,
      String? message,
      bool onOtherDevice = false,
      String? returnHost,
      VoidCallback? onReturn,
      bool goBackYourself = false,
      VoidCallback? onBackToWebsite,
      VoidCallback? onDone,
      bool settle = true,
    }) => _pump(
      tester,
      settle: settle,
      DisclosureFeedbackScreen(
        requestor: testParty("Webshop"),
        isSignatureSession: signature,
        message: message,
        onOtherDevice: onOtherDevice,
        returnHost: returnHost,
        onReturn: onReturn,
        goBackYourself: goBackYourself,
        onBackToWebsite: onBackToWebsite,
        shared: shared,
        onDismiss: (_) => onDone?.call(),
      ),
    );

    final email = _shared(
      "email",
      "Email address",
      attributes: [_value("email", "Email address", "anna@example.com")],
    );

    testWidgets("with whom, the card handed to their logo, and Done", (
      tester,
    ) async {
      var done = 0;
      await pump(tester, shared: [email], onDone: () => done++);

      // Handed over: no card left in the pile, the check on the logo, the
      // card small on its corner.
      final handover = find.byKey(const Key("share_done_handover"));
      expect(handover, findsOneWidget);
      expect(find.descendant(of: handover, matching: _bigCards), findsNothing);
      expect(_smallCards(), findsOneWidget);
      expect(
        find.descendant(
          of: handover,
          matching: find.byKey(const Key("share_done_check")),
        ),
        findsOneWidget,
      );
      expect(find.text("Shared with Webshop"), findsOneWidget);
      expect(
        find.text(
          "Email address has been shared. You'll find this in Activity.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key("share_done_next")), findsNothing);
      await tester.tap(find.byKey(const Key("ok_button")));
      expect(done, 1);
    });

    final five = [
      for (final n in ["one", "two", "three", "four", "five"]) _shared(n, n),
    ];

    testWidgets("five cards: all five in the stack, then all five handed "
        "over, the front one first", (tester) async {
      await pump(tester, shared: five, settle: false);
      final handover = find.byKey(const Key("share_done_handover"));
      List<String> left() => [
        for (final e
            in find.descendant(of: handover, matching: _bigCards).evaluate())
          (e.widget as CredentialCardArt).credential.name,
      ];
      expect(left(), hasLength(5));
      expect(find.byKey(const Key("share_done_check")), findsNothing);
      // One at a time, the front one first; the check once all are in.
      final counts = <int>[5];
      while (left().isNotEmpty) {
        await tester.pump(const Duration(milliseconds: 50));
        final n = left().length;
        if (n != counts.last) {
          counts.add(n);
          if (n == 4) expect(left(), isNot(contains("one")));
        }
      }
      expect(counts, [5, 4, 3, 2, 1, 0]);
      expect(_smallCards(), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("share_done_check")), findsOneWidget);
      // The first three come back small on the logo's corner, the front one
      // on top.
      final small = [
        for (final e in _smallCards().evaluate())
          (e.widget as CredentialCardArt).credential.name,
      ];
      expect(small, ["three", "two", "one"]);
      expect(find.textContaining("5 cards"), findsOneWidget);
    });

    testWidgets("five cards on a signed message: all five in the stack on "
        "the paper", (tester) async {
      await pump(tester, signature: true, message: "I agree", shared: five);
      expect(
        find.descendant(
          of: find.byKey(const Key("share_done_paper")),
          matching: find.byType(CredentialCardArt),
        ),
        findsNWidgets(5),
      );
      expect(find.textContaining("5 cards"), findsOneWidget);
    });

    testWidgets("from the share screen the logo flies in from where it was, "
        "and lands on its place above the cards", (tester) async {
      addTearDown(DoneFlight.reset);
      final was = GlobalKey();
      await _pump(
        tester,
        Builder(
          builder: (context) => Stack(
            children: [
              Positioned(
                left: 30,
                top: 300,
                child: SizedBox(key: was, width: 52, height: 52),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: TextButton(
                  key: const Key("share"),
                  onPressed: () {
                    DoneFlight.capture(context, logoKey: was);
                    Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        transitionDuration: Duration.zero,
                        pageBuilder: (_, _, _) => DisclosureFeedbackScreen(
                          requestor: testParty("Webshop"),
                          shared: [email],
                          onDismiss: (_) {},
                        ),
                      ),
                    );
                  },
                  child: const Text("Share"),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byKey(const Key("share")));
      await tester.pump();
      await tester.pump();
      final copy = find.byKey(const Key("done_logo_flight"));
      expect(copy, findsOneWidget);
      expect(tester.getRect(copy).topLeft, const Offset(30, 300));
      expect(tester.getRect(copy).width, 52);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      // Landed: the copy is gone, the logo 112 wide above the cards.
      expect(copy, findsNothing);
      final handover = tester.getRect(
        find.byKey(const Key("share_done_handover")),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key("share_done_handover")),
          matching: _bigCards,
        ),
        findsOneWidget,
      );
      expect(handover.width, 300);
      await tester.pumpAndSettle();
    });

    testWidgets("the small cards sit on the logo's bottom left corner, the "
        "check on its bottom right", (tester) async {
      await pump(tester, shared: [email, _shared("age", "Age limits")]);
      final minis = tester.getRect(find.byKey(const Key("share_done_minis")));
      final check = tester.getRect(find.byKey(const Key("share_done_check")));
      expect(_smallCards(), findsNWidgets(2));
      expect(minis.right, lessThan(check.left));
      expect(minis.bottom, closeTo(check.bottom, 12));
    });

    testWidgets("more cards: how many", (tester) async {
      await pump(tester, shared: [email, _shared("age", "Age limits")]);
      expect(find.textContaining("2 cards have been shared."), findsOneWidget);
    });

    testWidgets("on another device: continue there", (tester) async {
      await pump(tester, shared: [email], onOtherDevice: true);

      expect(
        find.textContaining("Continue on your other device."),
        findsOneWidget,
      );
    });

    testWidgets("with a link back: Back to {host} is the button", (
      tester,
    ) async {
      var returned = 0;
      await pump(
        tester,
        shared: [email],
        returnHost: "webshop.example",
        onReturn: () => returned++,
      );

      expect(
        find.descendant(
          of: find.byKey(const Key("ok_button")),
          matching: find.text("Back to webshop.example"),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key("ok_button")));
      expect(returned, 1);
    });

    testWidgets("Android without a link back: Back to the website", (
      tester,
    ) async {
      var back = 0;
      await pump(tester, shared: [email], onBackToWebsite: () => back++);

      expect(find.text("Back to the website"), findsOneWidget);
      await tester.tap(find.byKey(const Key("ok_button")));
      expect(back, 1);
    });

    testWidgets("iOS without a link back: tap ◀ at the top left, no button", (
      tester,
    ) async {
      await pump(tester, shared: [email], goBackYourself: true);

      expect(find.text("Go back to the website"), findsOneWidget);
      expect(find.textContaining("Tap ◀"), findsOneWidget);
      // No browser named: they may have come from any app.
      expect(find.textContaining("Safari"), findsNothing);
      expect(find.byKey(const Key("ok_button")), findsNothing);
    });

    testWidgets("a signature: the message on paper, signed with the card", (
      tester,
    ) async {
      await pump(tester, shared: [email], signature: true, message: "I agree");

      expect(find.text("Signed for Webshop"), findsOneWidget);
      expect(find.byKey(const Key("share_done_paper")), findsOneWidget);
      expect(find.text("I agree"), findsOneWidget);
      expect(
        find.textContaining("You signed this message with Email address."),
        findsOneWidget,
      );
    });

    testWidgets("a disclosure with an empty message: no paper", (tester) async {
      await pump(tester, shared: [email], message: "");

      expect(find.byKey(const Key("share_done_paper")), findsNothing);
      expect(find.byKey(const Key("signed_message")), findsNothing);
      expect(find.byKey(const Key("share_done_handover")), findsOneWidget);
    });

    testWidgets("nothing shared", (tester) async {
      await pump(tester);

      // The title, and the Done button.
      expect(find.text("Done"), findsNWidgets(2));
      expect(
        find.text(
          "Webshop received no data from you. You can find this in Activity.",
        ),
        findsOneWidget,
      );
      // Their logo with the check, without cards, also not small.
      expect(find.byKey(const Key("share_done_check")), findsOneWidget);
      expect(find.byType(CredentialCardArt), findsNothing);
      expect(find.byKey(const Key("share_done_minis")), findsNothing);
    });

    testWidgets("a card's last use: no note, no chip", (tester) async {
      await pump(tester, shared: [_shared("age", "Age limits", left: 1)]);

      expect(find.byKey(const Key("share_done_last_use")), findsNothing);
      expect(find.byKey(const Key("shared_card_chip")), findsNothing);
    });
  });

  testWidgets("call: shared, now call, with the number", (tester) async {
    var called = 0;
    await _pump(
      tester,
      CallInfoScreen(
        otherParty: "Gemeente",
        phoneNumber: "+31612345678",
        onContinue: () => called++,
      ),
    );

    expect(find.text("Shared. Now call Gemeente"), findsOneWidget);
    expect(find.text("+31612345678"), findsOneWidget);
    await tester.tap(find.text("Call Gemeente"));
    expect(called, 1);
  });

  testWidgets("pairing: who asks, and what the code is for", (tester) async {
    await _pump(
      tester,
      PairingRequired(
        pairingCode: "4827",
        requestor: testParty("Webshop"),
        onDismiss: () {},
      ),
      // The spinner waits for the website and never settles.
      settle: false,
    );

    expect(find.text("Enter this code on the website"), findsOneWidget);
    expect(
      find.textContaining("Webshop shows a field for it."),
      findsOneWidget,
    );
    expect(find.byKey(const Key("pairing_code_box_3")), findsOneWidget);
  });

  testWidgets("pairing: a requestor without a name is unknown", (tester) async {
    await _pump(
      tester,
      PairingRequired(
        pairingCode: "4827",
        requestor: testParty("", verified: false),
        onDismiss: () {},
      ),
      settle: false,
    );

    // The shield and the general instruction, not an empty card.
    expect(find.byType(RequestorCard), findsNothing);
    expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
    expect(find.textContaining("shows a field for it"), findsNothing);
    expect(find.byKey(const Key("pairing_code_box_3")), findsOneWidget);
  });

  testWidgets("pairing: a named requestor has its card", (tester) async {
    await _pump(
      tester,
      PairingRequired(
        pairingCode: "4827",
        requestor: testParty("Webshop"),
        onDismiss: () {},
      ),
      settle: false,
    );
    expect(find.byType(RequestorCard), findsOneWidget);
    expect(find.byIcon(Icons.verified_user_rounded), findsNothing);
  });
}
