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

  testWidgets("one card: the card, its chips and every value", (tester) async {
    await _pump(tester, IssuancePermission(issuedCredentials: [email]));

    expect(
      find.text("Do you want to add this data to your Yivi app?"),
      findsOneWidget,
    );
    expect(find.byType(CardPile), findsNothing);
    expect(find.text("by Gemeente"), findsOneWidget);
    expect(find.text("me@example.com"), findsOneWidget);
    expect(find.byKey(const Key("issuance_context")), findsNothing);
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

    expect(
      find.text("Do you want to add these 3 cards to your Yivi app?"),
      findsOneWidget,
    );
    expect(find.byType(CardPile), findsOneWidget);
    expect(find.text("3 cards"), findsOneWidget);
    expect(find.text("All cards are added together"), findsOneWidget);
    for (final i in [0, 1, 2]) {
      expect(find.byKey(Key("issuance_card_$i")), findsOneWidget);
    }
    expect(find.text("Anna"), findsOneWidget);

    await tester.tap(find.text("Add 3 cards"));
    expect(added, 1);
  });

  testWidgets("cards from several issuers say how many", (tester) async {
    await _pump(
      tester,
      IssuancePermission(
        issuedCredentials: [
          email,
          _card("bank", issuer: "Bank"),
        ],
      ),
    );

    expect(find.text("from 2 issuers"), findsOneWidget);
  });

  testWidgets("inside a request: which request, and which step", (
    tester,
  ) async {
    await _pump(
      tester,
      IssuancePermission(
        issuedCredentials: [email],
        forRequest: testSession(steps: twoSteps),
        returnedFromIssuer: "Gemeente",
      ),
    );

    expect(find.text("For Test Verifier · step 2 of 2"), findsOneWidget);
    // The request says more than where the user came back from.
    expect(find.textContaining("Back from"), findsNothing);
  });

  testWidgets("one step needs no number", (tester) async {
    await _pump(
      tester,
      IssuancePermission(
        issuedCredentials: [email],
        forRequest: testSession(steps: [twoSteps.last]),
      ),
    );

    expect(find.text("For Test Verifier"), findsOneWidget);
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
    expect(
      find.text(
        "Test Verifier needs BIC RABONL2U. This card has INGBNL2A, so it "
        "won't count for this request. You can still add it.",
      ),
      findsOneWidget,
    );
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

  testWidgets("back from the issuer's website, outside a request", (
    tester,
  ) async {
    await _pump(
      tester,
      IssuancePermission(
        issuedCredentials: [email],
        returnedFromIssuer: "Gemeente",
      ),
    );

    expect(find.text("Back from the website of Gemeente"), findsOneWidget);
  });

  testWidgets("a nested session screen reads the request underneath", (
    tester,
  ) async {
    const nestedId = 2;
    await _pump(
      tester,
      const SessionScreen(sessionId: nestedId, hasUnderlyingSession: true),
      overrides: [
        sessionStateProvider(
          nestedId,
        ).overrideWith((ref) => Stream.value(_issuance(nestedId, [email]))),
        underlyingDisclosureProvider(
          nestedId,
        ).overrideWith((ref) => Stream.value(testSession(steps: twoSteps))),
      ],
    );

    expect(find.byType(IssuancePermission), findsOneWidget);
    expect(find.text("For Test Verifier · step 2 of 2"), findsOneWidget);
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
