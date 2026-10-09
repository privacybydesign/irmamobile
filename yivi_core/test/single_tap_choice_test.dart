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
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_discon_stepper.dart";
import "package:yivi_core/src/screens/session/widgets/issue_during_disclosure_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/irma_card.dart";
import "package:yivi_core/src/widgets/radio_indicator.dart";

import "pump_and_load_locales.dart";

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
  hash: "hash-$id",
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
  id: 1,
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

Override _flag({required bool on}) => featureFlagProvider(
  FeatureFlag.singleTapChoice,
).overrideWith((ref) => Stream.value(on));

Widget _app({
  required Widget home,
  required List<Override> overrides,
  List<GoRoute> extraRoutes = const [],
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: "/", builder: (_, _) => home),
      ...extraRoutes,
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

DisclosurePickOne _passportOrIdCard({
  List<CredentialDescriptor> obtainable = const [],
}) => DisclosurePickOne(
  optional: false,
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
      await pumpAndLoadLocales(
        tester,
        _app(
          overrides: [],
          home: Scaffold(body: stepper(onObtainOption: (_) {})),
        ),
      );

      expect(find.text("Passport or ID card"), findsOneWidget);
      expect(
        find.text("Not in your app yet. Tap what you want to obtain."),
        findsOneWidget,
      );
      expect(find.text("Obtain"), findsNWidgets(2));
      expect(find.byType(RadioIndicator), findsNothing);
    });

    testWidgets("a single tap reports the tapped option", (tester) async {
      ({int stepIndex, int optionIndex})? obtained;
      await pumpAndLoadLocales(
        tester,
        _app(
          overrides: [],
          home: Scaffold(body: stepper(onObtainOption: (c) => obtained = c)),
        ),
      );

      await tester.tap(find.text("ID card"));

      expect(obtained, (stepIndex: 0, optionIndex: 1));
    });

    testWidgets("an option without an issue url is not tappable", (
      tester,
    ) async {
      ({int stepIndex, int optionIndex})? obtained;
      await pumpAndLoadLocales(
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

      expect(find.text("Obtain"), findsOneWidget);
      await tester.tap(find.text("ID card"));

      expect(obtained, isNull);
    });

    testWidgets("without the callback it keeps the radio buttons", (
      tester,
    ) async {
      await pumpAndLoadLocales(
        tester,
        _app(
          overrides: [],
          home: Scaffold(body: stepper()),
        ),
      );

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

    Widget app({required bool flagOn, required List<String> visited}) => _app(
      overrides: [
        _flag(on: flagOn),
        sessionStateProvider(1).overrideWith((ref) => Stream.value(session)),
      ],
      home: IssueDuringDisclosureScreen(
        sessionId: 1,
        onDismiss: () {},
        onClose: () {},
      ),
      extraRoutes: [
        GoRoute(
          path: "/home/add_data/details",
          builder: (_, state) {
            visited.add(state.uri.queryParameters["credential"]!);
            return const Scaffold(body: Text("details"));
          },
        ),
      ],
    );

    testWidgets("flag on: tapping an option starts obtaining it", (
      tester,
    ) async {
      final visited = <String>[];
      await pumpAndLoadLocales(tester, app(flagOn: true, visited: visited));

      expect(find.byKey(const Key("bottom_bar_primary")), findsNothing);

      await tester.ensureVisible(find.text("ID card"));
      await tester.tap(find.text("ID card"));
      await tester.pumpAndSettle();

      expect(find.text("details"), findsOneWidget);
      expect(visited.single, contains('"credential_id":"idcard"'));
    });

    testWidgets("flag off: radio buttons and the obtain button stay", (
      tester,
    ) async {
      await pumpAndLoadLocales(tester, app(flagOn: false, visited: []));

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
    Widget app({required bool flagOn, List<DisclosurePickOne>? choices}) {
      final session = _session(choices: choices ?? [_passportOrIdCard()]);

      return _app(
        overrides: [
          _flag(on: flagOn),
          sessionStateProvider(1).overrideWith((ref) => Stream.value(session)),
        ],
        home: DisclosureChoicesOverview(
          sessionState: session,
          onDismiss: () {},
          onChoicesConfirmed: (_) {},
        ),
      );
    }

    testWidgets("flag on: label above the values, Switch in the footer", (
      tester,
    ) async {
      await pumpAndLoadLocales(tester, app(flagOn: true));

      expect(find.text("PASSPORT OR ID CARD"), findsOneWidget);
      expect(find.text("Jansen"), findsOneWidget);
      expect(find.text("Certified by RvIG"), findsOneWidget);
      expect(find.byKey(const Key("choice_switch_button")), findsOneWidget);
      expect(find.text("Switch"), findsOneWidget);
      expect(find.text("Change choice"), findsNothing);
    });

    testWidgets("flag off: the Change choice button stays", (tester) async {
      await pumpAndLoadLocales(tester, app(flagOn: false));

      expect(find.text("Change choice"), findsOneWidget);
      expect(find.text("PASSPORT OR ID CARD"), findsNothing);
      expect(find.text("Certified by RvIG"), findsNothing);
      expect(find.byKey(const Key("choice_switch_button")), findsNothing);
    });

    testWidgets("flag on: the label names a credential once", (tester) async {
      await pumpAndLoadLocales(
        tester,
        app(
          flagOn: true,
          choices: [
            DisclosurePickOne(
              optional: false,
              ownedOptions: [
                _bundle(_instance("email1", "E-mail", "a@example.com")),
                _bundle(_instance("email2", "E-mail", "b@example.com")),
              ],
            ),
          ],
        ),
      );

      expect(find.text("E-MAIL"), findsOneWidget);
      expect(find.byKey(const Key("choice_switch_button")), findsOneWidget);
    });

    testWidgets("flag on: a single option has no Switch button", (
      tester,
    ) async {
      await pumpAndLoadLocales(
        tester,
        app(
          flagOn: true,
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

      expect(find.text("Jansen"), findsOneWidget);
      expect(find.byKey(const Key("choice_switch_button")), findsNothing);
      expect(find.text("Certified by RvIG"), findsNothing);
    });

    testWidgets("flag on: Switch opens the sheet and a tap picks and closes", (
      tester,
    ) async {
      await pumpAndLoadLocales(tester, app(flagOn: true));

      await tester.tap(find.byKey(const Key("choice_switch_button")));
      await tester.pumpAndSettle();

      expect(find.text("What do you want to share?"), findsOneWidget);
      expect(
        find.text(
          "Gemeente accepts: Passport or ID card. Tap what you want to share.",
        ),
        findsOneWidget,
      );
      // No radio circles, and the current option is the highlighted one.
      expect(find.byType(RadioIndicator), findsNothing);
      expect(
        _cardStyles(tester).where((s) => s == IrmaCardStyle.highlighted),
        hasLength(1),
      );

      await tester.tap(find.text("de Vries"));
      await tester.pumpAndSettle();

      expect(find.text("What do you want to share?"), findsNothing);
      expect(find.text("de Vries"), findsOneWidget);
      expect(find.text("Jansen"), findsNothing);
    });

    testWidgets("flag on: the sheet lists options that are not in the app", (
      tester,
    ) async {
      final choice = DisclosurePickOne(
        optional: false,
        ownedOptions: [_bundle(_instance("passport", "Passport", "Jansen"))],
        obtainableOptions: [idCard],
      );
      await pumpAndLoadLocales(tester, app(flagOn: true, choices: [choice]));

      await tester.tap(find.byKey(const Key("choice_switch_button")));
      await tester.pumpAndSettle();

      expect(find.text("ID card"), findsOneWidget);
      expect(find.text("Obtain"), findsOneWidget);
      expect(find.text("Done"), findsNothing);
    });

    testWidgets("flag off: Change choice opens the old screen", (tester) async {
      await pumpAndLoadLocales(tester, app(flagOn: false));

      await tester.tap(find.text("Change choice"));
      await tester.pumpAndSettle();

      expect(find.text("What do you want to share?"), findsNothing);
      expect(find.byType(RadioIndicator), findsNWidgets(2));
      expect(find.text("Done"), findsOneWidget);
    });
  });
}
