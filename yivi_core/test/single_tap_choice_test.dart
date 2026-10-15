import "dart:async";

import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/feature_flag_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/session/widgets/choice_option_row.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_discon_stepper.dart";
import "package:yivi_core/src/screens/session/widgets/issue_during_disclosure_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/radio_indicator.dart";

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
}
