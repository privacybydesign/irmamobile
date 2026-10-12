import "dart:async";

import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/feature_flag_provider.dart";
import "package:yivi_core/src/providers/issue_during_disclosure_provider.dart";
import "package:yivi_core/src/providers/missing_data_flow_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/choice_option_row.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_discon_stepper.dart";
import "package:yivi_core/src/screens/session/widgets/issue_during_disclosure_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/irma_card.dart";
import "package:yivi_core/src/widgets/radio_indicator.dart";

import "missing_data_fixtures.dart";
import "support/pump_translated.dart";

const _sessionId = 1;
const _detailsPath = "/home/add_data/details";

TrustedParty _party(String name) =>
    TrustedParty(id: name, name: name, url: null, parent: null, verified: true);

CredentialDescriptor _descriptor(
  String id,
  String name, {
  String? issueUrl = "https://issue.example",
}) => CredentialDescriptor(
  credentialId: id,
  name: name,
  issuer: _party("Issuer"),
  category: null,
  attributes: [],
  issueURL: issueUrl,
);

SelectableCredentialInstance _instance(
  String id,
  String name,
  String surname,
) => SelectableCredentialInstance(
  credentialId: id,
  hash: "hash-$id-$surname",
  name: name,
  issuer: _party("RvIG"),
  format: CredentialFormat.idemix,
  attributes: [
    Attribute(
      claimPath: ["surname"],
      displayName: "Surname",
      value: AttributeValue(type: AttributeType.string, string: surname),
    ),
  ],
  revoked: false,
  revocationSupported: false,
);

DisclosureBundle _bundle(SelectableCredentialInstance instance) =>
    DisclosureBundle(credentials: [instance]);

IssuanceBundle _issuanceBundle(CredentialDescriptor descriptor) =>
    IssuanceBundle(credentials: [descriptor]);

SessionState _session({
  List<DisclosurePickOne>? choices,
  List<IssuanceStep>? steps,
}) => SessionState(
  id: _sessionId,
  protocol: "irma",
  type: SessionType.disclosure,
  status: SessionStatus.requestPermission,
  requestor: _party("Gemeente"),
  disclosurePlan: DisclosurePlan(
    disclosureChoicesOverview: choices,
    issueDuringDisclosure: steps == null
        ? null
        : IssueDuringDisclosure(steps: steps, issuedCredentialIds: {}),
  ),
);

enum _Flag { on, off }

Override _flag(_Flag flag) => featureFlagProvider(
  FeatureFlag.singleTapChoice,
).overrideWith((ref) => Stream.value(flag == _Flag.on));

/// The app with [home] at "/" and a stand-in for the add data details screen
/// that records the credential it was opened for.
Widget _app({
  required Widget home,
  required List<Override> overrides,
  List<String>? obtained,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: "/", builder: (_, _) => home),
      GoRoute(
        path: _detailsPath,
        builder: (_, state) {
          obtained?.add(state.uri.queryParameters["credential"]!);
          return const Scaffold(body: Text("details"));
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
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
          ...GlobalMaterialLocalizations.delegates,
        ],
      ),
    ),
  );
}

/// The share screen, rebuilt with every session state like SessionScreen does.
class _ShareScreen extends ConsumerWidget {
  const _ShareScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider(_sessionId)).value;
    if (session == null) return const SizedBox();

    return DisclosureChoicesOverview(
      sessionState: session,
      onDismiss: () {},
      onChoicesConfirmed: (_) {},
    );
  }
}

enum _Optionality { required, optional }

DisclosurePickOne _passportOrIdCard({
  _Optionality optionality = _Optionality.required,
  List<CredentialDescriptor> obtainable = const [],
}) => DisclosurePickOne(
  optional: optionality == _Optionality.optional,
  ownedOptions: [
    _bundle(_instance("passport", "Passport", "Jansen")),
    _bundle(_instance("idcard", "ID card", "de Vries")),
  ],
  obtainableOptions: obtainable,
);

List<IrmaCardStyle> _cardStyles(WidgetTester tester) => tester
    .widgetList<YiviCredentialCard>(find.byType(YiviCredentialCard))
    .map((c) => c.style)
    .toList();

final _footer = find.byKey(const Key("choice_card_footer"));

void main() {
  final passport = _descriptor("passport", "Passport");
  final idCard = _descriptor("idcard", "ID card");

  group("choice step in the collect data list", () {
    DisclosureDisconStepper stepper({
      ValueChanged<({int stepIndex, int optionIndex})>? onObtainOption,
      List<IssuanceBundle>? options,
    }) => DisclosureDisconStepper(
      steps: [
        IssuanceStep(
          options:
              options ?? [_issuanceBundle(passport), _issuanceBundle(idCard)],
        ),
      ],
      currentStepIndex: 0,
      selectedOptionPerStep: const [0],
      issuedCredentialIds: const {},
      onObtainOption: onObtainOption,
    );

    testWidgets("lists one tappable row per option and no radio buttons", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpTranslated(
        tester,
        _app(
          overrides: [],
          home: Scaffold(body: stepper(onObtainOption: (_) {})),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Passport or ID card"), findsOneWidget);
      expect(
        find.text("Not in your app yet. Tap what you want to obtain."),
        findsOneWidget,
      );
      expect(find.text("Obtain"), findsNWidgets(2));
      expect(find.byType(RadioIndicator), findsNothing);
      expect(
        tester.getSemantics(find.byType(ChoiceOptionRow).last),
        isSemantics(
          label: "ID card\nObtain",
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets("a single tap reports the tapped option", (tester) async {
      ({int stepIndex, int optionIndex})? obtained;
      await pumpTranslated(
        tester,
        _app(
          overrides: [],
          home: Scaffold(body: stepper(onObtainOption: (c) => obtained = c)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("ID card"));

      expect(obtained, (stepIndex: 0, optionIndex: 1));
    });

    testWidgets("an option without an issue url is not tappable", (
      tester,
    ) async {
      ({int stepIndex, int optionIndex})? obtained;
      await pumpTranslated(
        tester,
        _app(
          overrides: [],
          home: Scaffold(
            body: stepper(
              onObtainOption: (c) => obtained = c,
              options: [
                _issuanceBundle(passport),
                _issuanceBundle(
                  _descriptor("idcard", "ID card", issueUrl: null),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Obtain"), findsOneWidget);
      await tester.tap(find.text("ID card"));

      expect(obtained, isNull);
    });

    testWidgets("without the callback it keeps the radio buttons", (
      tester,
    ) async {
      await pumpTranslated(
        tester,
        _app(
          overrides: [],
          home: Scaffold(body: stepper()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Make a choice"), findsOneWidget);
      expect(find.byType(RadioIndicator), findsNWidgets(2));
      expect(find.text("Obtain"), findsNothing);
    });
  });

  group("collect data screen", () {
    final session = _session(
      steps: [
        IssuanceStep(
          options: [_issuanceBundle(passport), _issuanceBundle(idCard)],
        ),
      ],
    );

    Widget app(_Flag flag, List<String> obtained) => _app(
      overrides: [
        _flag(flag),
        sessionStateProvider(
          _sessionId,
        ).overrideWith((ref) => Stream.value(session)),
      ],
      home: IssueDuringDisclosureScreen(
        sessionId: _sessionId,
        onDismiss: () {},
        onClose: () {},
      ),
      obtained: obtained,
    );

    testWidgets("flag on: a tap on an option starts obtaining it", (
      tester,
    ) async {
      final obtained = <String>[];
      await pumpTranslated(tester, app(_Flag.on, obtained));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key("bottom_bar_primary")), findsNothing);
      expect(find.byKey(const Key("bottom_bar_secondary")), findsOneWidget);

      await tester.ensureVisible(find.text("ID card"));
      await tester.tap(find.text("ID card"));
      await tester.pumpAndSettle();

      expect(find.text("details"), findsOneWidget);
      expect(obtained.single, contains('"credential_id":"idcard"'));
    });

    testWidgets("flag off: radio buttons and the obtain button stay", (
      tester,
    ) async {
      await pumpTranslated(tester, app(_Flag.off, []));
      await tester.pumpAndSettle();

      expect(find.byType(RadioIndicator), findsNWidgets(2));
      expect(find.byKey(const Key("bottom_bar_primary")), findsOneWidget);
      expect(find.text("Obtain data"), findsOneWidget);
      expect(
        find.text("Not in your app yet. Tap what you want to obtain."),
        findsNothing,
      );
    });
  });

  group("share screen card for a choice", () {
    Widget app(
      _Flag flag, {
      List<DisclosurePickOne>? choices,
      Stream<SessionState>? sessions,
      List<String>? obtained,
    }) {
      final session = _session(choices: choices ?? [_passportOrIdCard()]);

      return _app(
        overrides: [
          _flag(flag),
          sessionStateProvider(
            _sessionId,
          ).overrideWith((ref) => sessions ?? Stream.value(session)),
        ],
        home: const _ShareScreen(),
        obtained: obtained,
      );
    }

    testWidgets("flag on: label in the card, issuer band below it", (
      tester,
    ) async {
      await pumpTranslated(tester, app(_Flag.on));
      await tester.pumpAndSettle();

      final card = find.byType(YiviCredentialCard);
      expect(
        find.descendant(of: card, matching: find.text("PASSPORT OR ID CARD")),
        findsOneWidget,
      );
      expect(find.text("Jansen"), findsOneWidget);
      expect(
        find.descendant(of: _footer, matching: find.text("Certified by RvIG")),
        findsOneWidget,
      );
      expect(tester.getTopLeft(_footer).dy, tester.getBottomLeft(card).dy);
      expect(find.text("Change choice"), findsNothing);
      expect(find.text("Switch"), findsNothing);
    });

    testWidgets("flag on: the band is a button that changes the choice", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpTranslated(tester, app(_Flag.on));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(_footer),
        isSemantics(
          label: "Certified by RvIG",
          hint: "Change choice",
          isButton: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets("flag off: the Change choice button stays", (tester) async {
      await pumpTranslated(tester, app(_Flag.off));
      await tester.pumpAndSettle();

      expect(find.text("Change choice"), findsOneWidget);
      expect(find.text("PASSPORT OR ID CARD"), findsNothing);
      expect(find.text("Certified by RvIG"), findsNothing);
      expect(_footer, findsNothing);
    });

    testWidgets("flag on: instances of one credential get no label", (
      tester,
    ) async {
      await pumpTranslated(
        tester,
        app(
          _Flag.on,
          choices: [
            DisclosurePickOne(
              optional: false,
              ownedOptions: [
                _bundle(_instance("email", "E-mail", "a@example.com")),
                _bundle(_instance("email", "E-mail", "b@example.com")),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("E-MAIL"), findsNothing);
      expect(_footer, findsOneWidget);
    });

    testWidgets("flag on: a single option has no band", (tester) async {
      await pumpTranslated(
        tester,
        app(
          _Flag.on,
          choices: [
            DisclosurePickOne(
              optional: false,
              ownedOptions: [
                _bundle(_instance("passport", "Passport", "Jansen")),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Jansen"), findsOneWidget);
      expect(_footer, findsNothing);
      expect(find.text("Certified by RvIG"), findsNothing);
    });

    testWidgets("flag on: the band opens the sheet and a tap picks and closes", (
      tester,
    ) async {
      await pumpTranslated(tester, app(_Flag.on));
      await tester.pumpAndSettle();

      await tester.tap(_footer);
      await tester.pumpAndSettle();

      expect(find.text("What do you want to share?"), findsOneWidget);
      expect(
        find.text(
          "Gemeente accepts: Passport or ID card. Tap what you want to share.",
        ),
        findsOneWidget,
      );
      expect(find.byType(RadioIndicator), findsNothing);
      expect(find.text("Done"), findsNothing);
      // The share screen card behind the sheet plus the two options; only the
      // current option is highlighted.
      expect(_cardStyles(tester), [
        IrmaCardStyle.normal,
        IrmaCardStyle.highlighted,
        IrmaCardStyle.normal,
      ]);

      await tester.tap(find.text("de Vries"));
      await tester.pumpAndSettle();

      expect(find.text("What do you want to share?"), findsNothing);
      expect(find.text("de Vries"), findsOneWidget);
      expect(find.text("Jansen"), findsNothing);
    });

    testWidgets("flag on: owned options in the sheet are buttons", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpTranslated(tester, app(_Flag.on));
      await tester.pumpAndSettle();

      await tester.tap(_footer);
      await tester.pumpAndSettle();

      // Index 0 is the share screen card behind the sheet.
      final cards = find.byType(YiviCredentialCard);
      expect(
        tester.getSemantics(cards.at(1)),
        isSemantics(
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(cards.at(2)),
        isSemantics(isButton: true, hasSelectedState: true, hasTapAction: true),
      );
      semantics.dispose();
    });

    testWidgets("flag on: the sheet highlights the option picked earlier", (
      tester,
    ) async {
      await pumpTranslated(tester, app(_Flag.on));
      await tester.pumpAndSettle();

      await tester.tap(_footer);
      await tester.pumpAndSettle();
      await tester.tap(find.text("de Vries"));
      await tester.pumpAndSettle();
      await tester.tap(_footer);
      await tester.pumpAndSettle();

      expect(_cardStyles(tester), [
        IrmaCardStyle.normal,
        IrmaCardStyle.normal,
        IrmaCardStyle.highlighted,
      ]);
    });

    testWidgets("flag on: the sheet obtains an option not in the app", (
      tester,
    ) async {
      final obtained = <String>[];
      final choice = DisclosurePickOne(
        optional: false,
        ownedOptions: [_bundle(_instance("passport", "Passport", "Jansen"))],
        obtainableOptions: [idCard],
      );
      await pumpTranslated(
        tester,
        app(_Flag.on, choices: [choice], obtained: obtained),
      );
      await tester.pumpAndSettle();

      await tester.tap(_footer);
      await tester.pumpAndSettle();

      expect(find.text("ID card"), findsOneWidget);
      expect(find.text("Obtain"), findsOneWidget);

      await tester.tap(find.text("ID card"));
      await tester.pumpAndSettle();

      expect(find.text("details"), findsOneWidget);
      expect(obtained.single, contains('"credential_id":"idcard"'));
    });

    testWidgets("flag on: adding optional data uses the sheet", (tester) async {
      await pumpTranslated(
        tester,
        app(
          _Flag.on,
          choices: [_passportOrIdCard(optionality: _Optionality.optional)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Jansen"), findsNothing);

      await tester.tap(find.text("Add optional data"));
      await tester.pumpAndSettle();

      expect(find.text("What do you want to share?"), findsOneWidget);

      await tester.tap(find.text("de Vries"));
      await tester.pumpAndSettle();

      expect(find.text("What do you want to share?"), findsNothing);
      expect(find.text("Optional data"), findsOneWidget);
      expect(find.text("de Vries"), findsOneWidget);
    });

    testWidgets("flag on: optional data obtained from the sheet is added", (
      tester,
    ) async {
      final sessions = StreamController<SessionState>();
      addTearDown(sessions.close);
      sessions.add(
        _session(
          choices: [
            DisclosurePickOne(
              optional: true,
              ownedOptions: [
                _bundle(_instance("passport", "Passport", "Jansen")),
              ],
              obtainableOptions: [idCard],
            ),
          ],
        ),
      );
      await pumpTranslated(tester, app(_Flag.on, sessions: sessions.stream));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Add optional data"));
      await tester.pumpAndSettle();

      // The ID card was obtained while the sheet was open.
      sessions.add(
        _session(
          choices: [
            DisclosurePickOne(
              optional: true,
              ownedOptions: [
                _bundle(_instance("passport", "Passport", "Jansen")),
                _bundle(_instance("idcard", "ID card", "de Vries")),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // The new ID card is selected in the sheet and added to the share
      // screen behind it.
      expect(find.text("de Vries"), findsNWidgets(2));
      expect(_cardStyles(tester), [
        IrmaCardStyle.normal,
        IrmaCardStyle.normal,
        IrmaCardStyle.highlighted,
      ]);

      final sheetTitle = find.text("What do you want to share?");
      Navigator.of(tester.element(sheetTitle)).pop();
      await tester.pumpAndSettle();

      expect(find.text("Optional data"), findsOneWidget);
      expect(find.text("de Vries"), findsOneWidget);
      expect(find.text("Jansen"), findsNothing);
    });

    testWidgets("flag off: Change choice opens the old screen", (tester) async {
      await pumpTranslated(tester, app(_Flag.off));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Change choice"));
      await tester.pumpAndSettle();

      expect(find.text("What do you want to share?"), findsNothing);
      expect(find.byType(RadioIndicator), findsNWidgets(2));
      expect(find.text("Done"), findsOneWidget);
    });
  });

  group("choice in the missing data checklist", () {
    late MissingDataHarness harness;
    late GoRouter router;

    final paspoort = testDescriptor("paspoort");
    final idKaart = testDescriptor("idkaart");
    final choiceStep = testStep([
      [paspoort],
      [idKaart],
    ]);

    Future<void> setUp(WidgetTester tester, _Flag flag) async {
      router = GoRouter(
        initialLocation: "/session",
        routes: [
          GoRoute(
            path: "/session",
            builder: (_, _) => const SessionScreen(sessionId: testSessionId),
          ),
          GoRoute(
            path: _detailsPath,
            builder: (_, _) => const Scaffold(body: Text("details screen")),
          ),
        ],
      );
      harness = await MissingDataHarness.pump(tester, router);
      await tester.runAsync(
        () => harness.container
            .read(preferencesProvider)
            .setFeatureFlag(FeatureFlag.singleTapChoice, flag == _Flag.on),
      );
    }

    testWidgets("flag on: a dashed card with a row per option", (tester) async {
      await setUp(tester, _Flag.on);
      await harness.emit(tester, testSession(steps: [choiceStep]));

      expect(find.text("Cred paspoort of Cred idkaart"), findsOneWidget);
      expect(
        find.text("Nog niet in je app. Tik op wat je wilt ophalen."),
        findsOneWidget,
      );
      expect(find.byType(ChoiceOptionRow), findsNWidgets(2));
      expect(find.byType(RadioIndicator), findsNothing);
      expect(find.text("Maak een keuze"), findsNothing);
      expect(
        find.text("Haal eerst je cred paspoort of cred idkaart op"),
        findsOne,
      );
    });

    testWidgets("flag on: a tap on a row picks it and starts obtaining it", (
      tester,
    ) async {
      await setUp(tester, _Flag.on);
      await harness.emit(tester, testSession(steps: [choiceStep]));

      await tester.tap(find.text("Cred idkaart"));
      await tester.pumpAndSettle();

      expect(find.text("details screen"), findsOneWidget);
      expect(
        harness.container
            .read(issueDuringDisclosureProvider(testSessionId))
            .selectedOptionPerStep,
        [1],
      );
      expect(
        harness.container.read(missingDataFlowProvider)?.credentialId,
        "idkaart",
      );
    });

    testWidgets("flag on: the hint counts when more than the choice is "
        "missing", (tester) async {
      await setUp(tester, _Flag.on);
      await harness.emit(
        tester,
        testSession(
          steps: [
            testStep([
              [testDescriptor("email")],
            ]),
            choiceStep,
          ],
        ),
      );

      expect(find.text("Haal eerst de 2 ontbrekende gegevens op"), findsOne);
    });

    testWidgets("flag off: the radio choice and its hint stay", (tester) async {
      await setUp(tester, _Flag.off);
      await harness.emit(tester, testSession(steps: [choiceStep]));

      expect(find.text("Maak een keuze"), findsOneWidget);
      expect(find.byType(ChoiceOptionRow), findsNothing);
      expect(find.text("Haal eerst het ontbrekende gegeven op"), findsOne);
    });
  });
}
