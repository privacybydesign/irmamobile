import "dart:async";

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
import "package:yivi_core/src/data/session_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/requestor_card.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/card_pile.dart";

import "missing_data_fixtures.dart";
import "support/pump_translated.dart";

// The issuance permission: one card or a pile of several, and what it says
// when the issuance runs inside a request.

class _SilentBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

Attribute _value(String path, String name, String value) => Attribute(
  claimPath: [path],
  displayName: name,
  value: AttributeValue(type: AttributeType.string, string: value),
);

Credential _card(
  String id, {
  String issuer = "Gemeente",
  List<Attribute> attributes = const [],
}) => Credential(
  credentialId: id,
  hash: "hash-$id",
  name: "Card $id",
  issuer: testParty(issuer),
  credentialInstanceIds: const {},
  batchInstanceCountsRemaining: const {},
  attributes: attributes,
  revoked: false,
  revocationSupported: false,
  issueUrl: null,
);

CredentialDescriptor _wanted(
  String id, {
  List<Attribute> attributes = const [],
}) => CredentialDescriptor(
  credentialId: id,
  name: "Card $id",
  issuer: testParty("Gemeente"),
  category: null,
  attributes: attributes,
  issueURL: "https://gemeente.example",
);

SessionState _issuance(int id, List<Credential> cards) => SessionState(
  id: id,
  protocol: "irma",
  type: SessionType.issuance,
  status: SessionStatus.requestPermission,
  requestor: testParty("Gemeente"),
  offeredCredentials: cards,
);

Future<List<Override>> _env() async {
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

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
}) async {
  final env = (await tester.runAsync(_env))!;
  await pumpTranslated(
    tester,
    ProviderScope(
      overrides: [...env, ...overrides],
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
  await tester.pumpAndSettle();
}

void main() {
  final email = _card(
    "email",
    attributes: [_value("email", "Email address", "me@example.com")],
  );
  final twoSteps = [
    testStep([
      [_wanted("idin")],
    ]),
    testStep([
      [_wanted("email")],
    ]),
  ];

  testWidgets("one card: who gives it, and the card with every value", (
    tester,
  ) async {
    await _pump(
      tester,
      IssuancePermission(issuedCredentials: [email], onGivePermission: () {}),
    );

    // The same question page as in the Change sheet.
    final heading = find.byKey(const Key("issuance_heading"));
    expect(
      find.descendant(of: heading, matching: find.text("You get a card from")),
      findsOneWidget,
    );
    expect(
      find.descendant(of: heading, matching: find.text("Gemeente")),
      findsOneWidget,
    );
    expect(
      find.descendant(of: heading, matching: find.text("Registered with Yivi")),
      findsOneWidget,
    );
    expect(find.text("THIS GOES IN YOUR APP"), findsOneWidget);
    expect(find.byKey(const Key("issuance_card_0")), findsOneWidget);
    expect(find.text("Add"), findsOneWidget);
    expect(find.byType(CardPile), findsNothing);
    expect(find.text("me@example.com"), findsOneWidget);
    expect(find.byKey(const Key("issuance_mismatch")), findsNothing);
  });

  testWidgets("several cards: a pile, a group each, added together", (
    tester,
  ) async {
    var added = 0;
    await _pump(
      tester,
      IssuancePermission(
        issuedCredentials: [
          email,
          _card("phone", attributes: [_value("phone", "Phone", "0612345678")]),
          _card("name", attributes: [_value("name", "Name", "Anna")]),
        ],
        onGivePermission: () => added++,
      ),
    );

    expect(find.text("You get 3 cards from"), findsOneWidget);
    for (final i in [0, 1, 2]) {
      expect(find.byKey(Key("issuance_card_$i")), findsOneWidget);
    }
    expect(find.text("Anna"), findsOneWidget);

    await tester.tap(find.text("Add 3 cards"));
    expect(added, 1);
  });

  testWidgets("the band under the bar comes with who gives the card", (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await _pump(
      tester,
      IssuancePermission(
        issuedCredentials: [
          for (var n = 0; n < 4; n++)
            _card(
              "card$n",
              attributes: [
                for (var f = 0; f < 4; f++)
                  _value("f$f", "Field $f", "value $n.$f"),
              ],
            ),
        ],
      ),
    );
    final band = find.byKey(const Key("scroll_edge_band"));
    final bar = find.byKey(const Key("requestor_compact_bar"));
    final scroll = find.byKey(const Key("issuance_scroll_view"));
    expect(band, findsNothing);
    expect(bar, findsNothing);
    // Under the bar, but the large title still shows.
    await tester.drag(scroll, const Offset(0, -12));
    await tester.pumpAndSettle();
    expect(band, findsNothing);
    expect(bar, findsNothing);
    // Past the issuer's name: who gives the card in the bar, as on the
    // share screen, and the band with it.
    await tester.drag(scroll, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(band, findsOneWidget);
    expect(
      find.descendant(of: bar, matching: find.text("Gemeente")),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.text("gives you 4 cards")),
      findsOneWidget,
    );
    await tester.drag(scroll, const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(band, findsNothing);
    expect(bar, findsNothing);
  });

  testWidgets("the issuer's logo is a hero into its trust sheet, as the "
      "requestor's on the share screen", (tester) async {
    await _pump(
      tester,
      IssuancePermission(issuedCredentials: [_card("email")]),
    );
    final logo = find.byWidgetPredicate(
      (w) => w is Hero && w.tag == requestorLogoHeroTag(testParty("Gemeente")),
    );
    expect(logo, findsOneWidget);
    await tester.tap(find.byKey(const Key("session_requestor_info")));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // In flight: the logo goes from the card into the sheet.
    expect(
      find.descendant(of: find.byType(Overlay), matching: logo),
      findsWidgets,
    );
    await tester.pumpAndSettle();
    // In the sheet, and back in the card under it (offstage) to fly back to.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Hero && w.tag == requestorLogoHeroTag(testParty("Gemeente")),
        skipOffstage: false,
      ),
      findsNWidgets(2),
    );
  });

  final phone = _card(
    "phone",
    attributes: [_value("phone", "Phone", "0612345678")],
  );

  testWidgets("inside a request: what it asks for is Asked, the rest Comes "
      "too", (tester) async {
    await _pump(
      tester,
      IssuancePermission(
        issuedCredentials: [email, phone],
        forRequest: testSession(steps: twoSteps),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const Key("issuance_card_0")),
        matching: find.text("Asked"),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key("issuance_card_1")),
        matching: find.text("Comes too"),
      ),
      findsOneWidget,
    );
  });

  testWidgets("one card inside a request: no chip", (tester) async {
    await _pump(
      tester,
      IssuancePermission(
        issuedCredentials: [email],
        forRequest: testSession(steps: twoSteps),
      ),
    );

    expect(find.text("Asked"), findsNothing);
    expect(find.text("Comes too"), findsNothing);
  });

  testWidgets("a value the request cannot use is warned about first", (
    tester,
  ) async {
    final bank = _card("bank", attributes: [_value("bic", "BIC", "INGBNL2A")]);
    await _pump(
      tester,
      IssuancePermission(
        issuedCredentials: [bank],
        forRequest: testSession(
          steps: [
            testStep([
              [
                _wanted(
                  "bank",
                  attributes: [
                    Attribute(
                      claimPath: ["bic"],
                      displayName: "BIC",
                      requestedValue: AttributeValue(
                        type: AttributeType.string,
                        string: "RABONL2U",
                      ),
                    ),
                  ],
                ),
              ],
            ]),
          ],
        ),
      ),
    );

    expect(find.byKey(const Key("issuance_mismatch")), findsOneWidget);
    final box = find.byKey(const Key("issuance_mismatch"));
    expect(
      find.descendant(
        of: box,
        matching: find.text("This card doesn't count for Test Verifier"),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: box, matching: find.text("BIC RABONL2U")),
      findsOneWidget,
    );
    expect(
      find.descendant(of: box, matching: find.text("BIC INGBNL2A")),
      findsOneWidget,
    );
    expect(find.text("Doesn't count"), findsOneWidget);
  });

  testWidgets("a matching value needs no warning", (tester) async {
    await _pump(
      tester,
      IssuancePermission(
        issuedCredentials: [email],
        forRequest: testSession(
          steps: [
            testStep([
              [
                _wanted(
                  "email",
                  attributes: [
                    Attribute(
                      claimPath: ["email"],
                      displayName: "Email address",
                      requestedValue: AttributeValue(
                        type: AttributeType.string,
                        string: "me@example.com",
                      ),
                    ),
                  ],
                ),
              ],
            ]),
          ],
        ),
      ),
    );

    expect(find.byKey(const Key("issuance_mismatch")), findsNothing);
  });

  testWidgets("a nested session screen reads the request underneath", (
    tester,
  ) async {
    const nestedId = 2;
    await _pump(
      tester,
      const SessionScreen(sessionId: nestedId, hasUnderlyingSession: true),
      overrides: [
        sessionStateProvider(nestedId).overrideWith(
          (ref) => Stream.value(_issuance(nestedId, [email, phone])),
        ),
        underlyingDisclosureProvider(
          nestedId,
        ).overrideWith((ref) => Stream.value(testSession(steps: twoSteps))),
      ],
    );

    expect(find.byType(IssuancePermission), findsOneWidget);
    // The request's own card is marked as asked.
    expect(find.text("Asked"), findsOneWidget);
  });

  group("SessionRepository.underlyingDisclosure", () {
    late StreamController<Event> events;
    late SessionRepository sessions;

    setUp(() async {
      final overrides = await _env();
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      events = StreamController<Event>();
      sessions = SessionRepository(
        repo: container.read(irmaRepositoryProvider),
        eventStream: events.stream,
      );
      addTearDown(events.close);
    });

    Future<SessionState?> underlying(int id) =>
        sessions.underlyingDisclosure(id).first;

    void emit(SessionState s) => events.add(SessionStateEvent(sessionState: s));

    test("is the request waiting under the issuance", () async {
      emit(testSession(steps: twoSteps));
      emit(_issuance(2, [email]));
      await Future<void>.delayed(Duration.zero);

      expect((await underlying(2))?.id, testSessionId);
    });

    test("is null for an issuance started on its own", () async {
      emit(_issuance(2, [email]));
      await Future<void>.delayed(Duration.zero);

      expect(await underlying(2), isNull);
    });

    test("ignores a request started after the issuance", () async {
      emit(_issuance(1, [email]));
      emit(
        SessionState(
          id: 2,
          protocol: "irma",
          type: SessionType.disclosure,
          status: SessionStatus.requestPermission,
          requestor: testParty("Later"),
          disclosurePlan: DisclosurePlan(),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(await underlying(1), isNull);
    });
  });
}
