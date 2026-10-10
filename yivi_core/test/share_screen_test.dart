import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/schemaless/session_user_interaction.dart";
import "package:yivi_core/src/providers/feature_flag_provider.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_permission_confirm_dialog.dart";
import "package:yivi_core/src/screens/session/widgets/share_credential_card.dart";
import "package:yivi_core/src/screens/session/widgets/share_trust_bar.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/bold_markers_text.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";
import "package:yivi_core/src/widgets/yivi_themed_button.dart";

import "pump_and_load_locales.dart";

const _sessionId = 1;
const _detailsPath = "/home/credentials_details";
const _bsnCredentialId = "pbdf.gemeente.personalData";

final _shareButton = find.byKey(const Key("bottom_bar_primary"));
final _confirmButton = find.byKey(const Key("share_check_confirm"));
final _declineButton = find.byKey(const Key("share_check_decline"));
final _progressLine = find.byKey(const Key("share_check_progress"));
final _issuerBand = find.byKey(const Key("share_card_issuer_band"));

enum _Trust { known, unknown }

TrustedParty _party(
  String name, {
  String id = "party",
  _Trust trust = _Trust.known,
  String? url,
}) => TrustedParty(
  id: id,
  name: name,
  url: url,
  parent: null,
  verified: trust == _Trust.known,
);

Attribute _attribute(String id, String label, String value) => Attribute(
  claimPath: [id],
  displayName: label,
  value: AttributeValue(type: AttributeType.string, string: value),
);

SelectableCredentialInstance _instance({
  String credentialId = "pbdf.pbdf.passport",
  TrustedParty? issuer,
  List<Attribute>? attributes,
  int? expiryDate,
}) => SelectableCredentialInstance(
  credentialId: credentialId,
  hash: "hash-$credentialId",
  name: "Credential",
  issuer: issuer ?? _party("RvIG", id: "pbdf.rvig"),
  format: CredentialFormat.idemix,
  attributes: attributes ?? [_attribute("surname", "Surname", "Jansen")],
  expiryDate: expiryDate,
  revoked: false,
  revocationSupported: false,
);

enum _Need { mandatory, optional }

DisclosurePickOne _choice(
  List<SelectableCredentialInstance> options, {
  _Need need = _Need.mandatory,
}) => DisclosurePickOne(
  optional: need == _Need.optional,
  ownedOptions: [
    for (final o in options) DisclosureBundle(credentials: [o]),
  ],
);

SessionState _session({
  required List<DisclosurePickOne> choices,
  TrustedParty? requestor,
  SessionType type = SessionType.disclosure,
}) => SessionState(
  id: _sessionId,
  protocol: "irma",
  type: type,
  status: SessionStatus.requestPermission,
  requestor: requestor ?? _party("Gemeente"),
  disclosurePlan: DisclosurePlan(disclosureChoicesOverview: choices),
);

SelectableCredentialInstance _bsnInstance() => _instance(
  credentialId: _bsnCredentialId,
  attributes: [_attribute("bsn", "BSN", "999999999")],
);

enum _Flag { on, off }

Override _flag(_Flag flag) => featureFlagProvider(
  FeatureFlag.shareScreenV2,
).overrideWith((ref) => Stream.value(flag == _Flag.on));

Override _sessionOverride(SessionState session) => sessionStateProvider(
  _sessionId,
).overrideWith((ref) => Stream.value(session));

/// The overview rebuilt with the session state, like SessionScreen does.
class _Overview extends ConsumerWidget {
  final List<List<DisclosureDisconSelection>> confirmed;
  final List<int> dismissed;

  const _Overview({required this.confirmed, required this.dismissed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider(_sessionId)).value;
    if (session == null) return const SizedBox();

    return DisclosureChoicesOverview(
      sessionState: session,
      onDismiss: () => dismissed.add(0),
      onChoicesConfirmed: confirmed.add,
    );
  }
}

Widget _app({
  required Widget home,
  required List<Override> overrides,
  List<String>? openedDetails,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: "/", builder: (_, _) => home),
      GoRoute(
        path: _detailsPath,
        builder: (_, state) {
          openedDetails?.add(state.uri.queryParameters["credential_type_id"]!);
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

void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Opens the check sheet's route and lets it settle, without running the
/// 3 second wait of its button.
Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(_shareButton);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

bool _isDisabled(WidgetTester tester) =>
    tester.widget<YiviThemedButton>(_confirmButton).onPressed == null;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<List<DisclosureDisconSelection>> confirmed;
  late List<int> dismissed;

  setUp(() {
    confirmed = [];
    dismissed = [];
  });

  Future<void> pumpOverview(
    WidgetTester tester, {
    required SessionState session,
    _Flag flag = _Flag.on,
    List<String>? openedDetails,
  }) async {
    _usePhoneScreen(tester);
    await pumpAndLoadLocales(
      tester,
      _app(
        home: _Overview(confirmed: confirmed, dismissed: dismissed),
        overrides: [_flag(flag), _sessionOverride(session)],
        openedDetails: openedDetails,
      ),
    );
  }

  group("share screen with the flag on", () {
    testWidgets("has a close button and no app bar", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      expect(find.text("Share my data"), findsNothing);
      expect(find.byType(IrmaAppBar), findsNothing);
      expect(find.byType(IrmaCloseButton), findsOneWidget);

      await tester.tap(find.byType(IrmaCloseButton));
      await tester.pump();

      expect(dismissed, hasLength(1));
    });

    testWidgets("shows the requestor in the header", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      expect(
        find.text("Share your data with Gemeente", findRichText: true),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });

    testWidgets("shows the values first and the issuer band", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      expect(find.text("Surname"), findsOneWidget);
      expect(find.text("Jansen"), findsOneWidget);
      expect(find.text("Credential"), findsNothing);
      expect(find.text("Certified by RvIG"), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.text("New"), findsNothing);
    });

    testWidgets("shows one card per credential of a bundle", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            DisclosurePickOne(
              optional: false,
              ownedOptions: [
                DisclosureBundle(
                  credentials: [
                    _instance(),
                    _instance(
                      credentialId: "pbdf.sidn-pbdf.email",
                      attributes: [
                        _attribute("email", "Email", "a@example.com"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      expect(find.byType(ShareCredentialCard), findsNWidgets(2));
      expect(_issuerBand, findsNWidgets(2));
    });

    testWidgets("a tap on the issuer band opens the credential details", (
      tester,
    ) async {
      final opened = <String>[];
      await pumpOverview(
        tester,
        openedDetails: opened,
        session: _session(
          choices: [
            _choice([_instance(credentialId: "pbdf.sidn-pbdf.email")]),
          ],
        ),
      );

      await tester.tap(_issuerBand);
      await tester.pumpAndSettle();

      expect(opened, ["pbdf.sidn-pbdf.email"]);
    });

    testWidgets("a municipality credential names the municipality", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([
              _instance(
                credentialId: "pbdf.gemeente.address",
                issuer: _party("Your Municipality", id: "pbdf.gemeente"),
                attributes: [
                  _attribute("street", "Street", "Kerkstraat"),
                  _attribute("municipality", "Municipality", "Nijmegen"),
                ],
              ),
            ]),
          ],
        ),
      );

      expect(find.text("Certified by Nijmegen"), findsOneWidget);
      expect(find.text("Certified by Your Municipality"), findsNothing);
    });

    testWidgets("a municipality credential without one keeps the issuer", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([
              _instance(
                credentialId: _bsnCredentialId,
                issuer: _party("Your Municipality", id: "pbdf.gemeente"),
                attributes: [_attribute("fullname", "Name", "J. Jansen")],
              ),
            ]),
          ],
        ),
      );

      expect(find.text("Certified by Your Municipality"), findsOneWidget);
    });

    testWidgets("an expired credential says so and cannot be shared", (
      tester,
    ) async {
      final yesterday =
          DateTime.now()
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch ~/
          1000;
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance(expiryDate: yesterday)]),
          ],
        ),
      );

      expect(find.text("Expired"), findsOneWidget);
      expect(tester.widget<YiviThemedButton>(_shareButton).onPressed, isNull);
    });

    testWidgets("a choice between credentials keeps the change button", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance(), _instance(credentialId: "pbdf.pbdf.idcard")]),
          ],
        ),
      );

      expect(find.text("Change choice"), findsOneWidget);
    });

    testWidgets("optional data is added with the existing action card", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
            _choice([
              _instance(
                credentialId: "pbdf.sidn-pbdf.email",
                attributes: [_attribute("email", "Email", "a@example.com")],
              ),
            ], need: _Need.optional),
          ],
        ),
      );

      expect(find.text("Add optional data"), findsOneWidget);
      expect(find.text("a@example.com"), findsNothing);
    });

    testWidgets("signing keeps the existing screen", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          type: SessionType.signature,
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      expect(find.text("Share my data"), findsOneWidget);
      expect(find.byType(ShareTrustBar), findsNothing);
    });
  });

  group("trust bar", () {
    testWidgets("says a verified requestor is known", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      expect(
        find.text("Gemeente is known to us.", findRichText: true),
        findsOneWidget,
      );
      expect(find.text("What does this mean?"), findsOneWidget);

      final bar = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ShareTrustBar),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = bar.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFFD7EFE0));
      expect(decoration.borderRadius, BorderRadius.circular(12));
      expect(decoration.border, isNull);
    });

    testWidgets("says Yivi does not know an unverified requestor", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        session: _session(
          requestor: _party("shop.example.com", trust: _Trust.unknown),
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      expect(
        find.text("Yivi does not know shop.example.com.", findRichText: true),
        findsOneWidget,
      );

      final bar = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ShareTrustBar),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((bar.decoration! as BoxDecoration).color, const Color(0xFFF5DBDB));
    });

    testWidgets("the link opens the existing explanation sheet", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      await tester.tap(find.text("What does this mean?"));
      await tester.pumpAndSettle();

      expect(find.text("Known and unknown organizations"), findsOneWidget);
    });
  });

  group("sharing with the flag on", () {
    testWidgets("a known party and nothing sensitive is one tap", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      await tester.tap(_shareButton);
      await tester.pumpAndSettle();

      expect(confirmed, hasLength(1));
      expect(
        confirmed.single.single.credentials.single.credentialId,
        isNotEmpty,
      );
      expect(_confirmButton, findsNothing);
      expect(find.byType(DisclosurePermissionConfirmDialog), findsNothing);
    });

    testWidgets("sensitive data opens the sheet for the BSN", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_bsnInstance()]),
          ],
        ),
      );

      await _openSheet(tester);

      expect(find.text("You are sharing your BSN"), findsOneWidget);
      expect(
        find.text(
          "Your citizen service number is sensitive. Only share it if you know why Gemeente needs it.",
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _confirmButton, matching: find.text("Share")),
        findsOneWidget,
      );
      expect(find.text("Don't share"), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(confirmed, isEmpty);
    });

    testWidgets("an unknown party opens the sheet for its host", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        session: _session(
          requestor: _party(
            "shop.example.com",
            trust: _Trust.unknown,
            url: "https://shop.example.com/pay?id=1",
          ),
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      await _openSheet(tester);

      expect(find.text("Do you trust shop.example.com?"), findsOneWidget);
      expect(
        find.text(
          "Yivi does not know who is behind this website. Only share your data if you are sure you are on the right website.",
        ),
        findsOneWidget,
      );
      expect(find.text("Share anyway"), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(confirmed, isEmpty);
    });

    testWidgets("an unknown party with the BSN gets the unknown party sheet", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        session: _session(
          requestor: _party(
            "shop.example.com",
            trust: _Trust.unknown,
            url: "https://shop.example.com",
          ),
          choices: [
            _choice([_bsnInstance()]),
          ],
        ),
      );

      await _openSheet(tester);

      expect(find.text("Do you trust shop.example.com?"), findsOneWidget);
      expect(find.text("You are sharing your BSN"), findsNothing);
    });

    testWidgets("the share button of the sheet waits for 3 seconds", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_bsnInstance()]),
          ],
        ),
      );

      await _openSheet(tester);

      expect(_isDisabled(tester), isTrue);
      expect(
        find.descendant(
          of: _confirmButton,
          matching: find.byType(ColorFiltered),
        ),
        findsOneWidget,
      );

      await tester.tap(_confirmButton);
      await tester.pump();
      expect(find.text("You are sharing your BSN"), findsOneWidget);
      expect(confirmed, isEmpty);

      await tester.pump(const Duration(seconds: 2));
      expect(_isDisabled(tester), isTrue);

      await tester.pump(const Duration(seconds: 1));
      expect(_isDisabled(tester), isFalse);
      expect(
        find.descendant(
          of: _confirmButton,
          matching: find.byType(ColorFiltered),
        ),
        findsNothing,
      );

      await tester.tap(_confirmButton);
      await tester.pumpAndSettle();

      expect(confirmed, hasLength(1));
      expect(find.text("You are sharing your BSN"), findsNothing);
    });

    testWidgets("a white line fills along the button while it waits", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_bsnInstance()]),
          ],
        ),
      );

      await _openSheet(tester);
      final early = tester
          .widget<FractionallySizedBox>(_progressLine)
          .widthFactor!;

      await tester.pump(const Duration(seconds: 1));
      final later = tester
          .widget<FractionallySizedBox>(_progressLine)
          .widthFactor!;

      expect(early, greaterThan(0));
      expect(later, greaterThan(early));
      expect(later, lessThan(1));

      await tester.pump(const Duration(seconds: 3));
      expect(_progressLine, findsNothing);
    });

    testWidgets("the button fades to full colour in 0.2 seconds", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_bsnInstance()]),
          ],
        ),
      );

      double opacity() => tester
          .widgetList<Opacity>(
            find.ancestor(of: _confirmButton, matching: find.byType(Opacity)),
          )
          .map((o) => o.opacity)
          .reduce((a, b) => a < b ? a : b);

      await _openSheet(tester);
      await tester.pump(const Duration(milliseconds: 2700));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_isDisabled(tester), isFalse);
      expect(opacity(), lessThan(1));

      await tester.pump(const Duration(milliseconds: 300));
      expect(opacity(), 1);
    });

    testWidgets("with reduced motion there is no line but it still waits", (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_bsnInstance()]),
          ],
        ),
      );

      await _openSheet(tester);
      expect(_progressLine, findsNothing);
      expect(_isDisabled(tester), isTrue);

      await tester.pump(const Duration(seconds: 2));
      expect(_isDisabled(tester), isTrue);

      await tester.pump(const Duration(seconds: 1));
      expect(_isDisabled(tester), isFalse);
      expect(
        find.ancestor(of: _confirmButton, matching: find.byType(Opacity)),
        findsNothing,
      );
    });

    testWidgets("the sheet scrolls with large text instead of overflowing", (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpOverview(
        tester,
        session: _session(
          requestor: _party(
            "shop.example.com",
            trust: _Trust.unknown,
            url: "https://shop.example.com",
          ),
          choices: [
            _choice([_instance()]),
          ],
        ),
      );
      tester.view.physicalSize = const Size(360 * 3, 640 * 3);

      await _openSheet(tester);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(_declineButton);
      await tester.pump();
      await tester.tap(_declineButton);
      await tester.pumpAndSettle();

      expect(find.text("Do you trust shop.example.com?"), findsNothing);
    });

    testWidgets("Don't share closes the sheet without sharing", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_bsnInstance()]),
          ],
        ),
      );

      await _openSheet(tester);
      await tester.tap(_declineButton);
      await tester.pumpAndSettle();

      expect(confirmed, isEmpty);
      expect(find.text("You are sharing your BSN"), findsNothing);
      expect(_shareButton, findsOneWidget);
    });
  });

  group("flag off", () {
    testWidgets("shows the existing screen", (tester) async {
      await pumpOverview(
        tester,
        flag: _Flag.off,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      expect(find.text("Share my data"), findsOneWidget);
      expect(find.text("Share data"), findsOneWidget);
      expect(find.byType(ShareTrustBar), findsNothing);
      expect(find.byType(ShareCredentialCard), findsNothing);
      expect(find.text("Certified by RvIG"), findsNothing);
    });

    testWidgets("confirms at once and leaves the dialog to the session", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        flag: _Flag.off,
        session: _session(
          choices: [
            _choice([_bsnInstance()]),
          ],
        ),
      );

      await tester.tap(_shareButton);
      await tester.pumpAndSettle();

      expect(confirmed, hasLength(1));
      expect(_confirmButton, findsNothing);
    });
  });

  group("session screen", () {
    late _RecordingBridge bridge;

    setUp(() => bridge = _RecordingBridge());

    Future<void> pumpSession(
      WidgetTester tester, {
      required _Flag flag,
      required SessionState session,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await IrmaPreferences.fromInstance(
        mostRecentTermsUrlNl: "",
        mostRecentTermsUrlEn: "",
      );
      await prefs.clearAll();
      await prefs.setCompletedDisclosurePermissionIntro(true);
      final repo = IrmaRepository(client: bridge, preferences: prefs);
      addTearDown(repo.close);

      _usePhoneScreen(tester);
      await pumpAndLoadLocales(
        tester,
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            irmaRepositoryProvider.overrideWithValue(repo),
            _flag(flag),
            _sessionOverride(session),
          ],
          child: IrmaRepositoryProvider(
            repository: repo,
            child: IrmaTheme(
              builder: (_) => MaterialApp(
                localizationsDelegates: [
                  FlutterI18nDelegate(
                    translationLoader: FileTranslationLoader(
                      basePath: "assets/locales",
                      forcedLocale: const Locale("en", "EN"),
                    ),
                  ),
                  ...GlobalMaterialLocalizations.delegates,
                ],
                home: const SessionScreen(sessionId: _sessionId),
              ),
            ),
          ),
        ),
      );
    }

    Iterable<SessionUserInteractionEvent> permissions() => bridge.dispatched
        .whereType<SessionUserInteractionEvent>()
        .where((e) => e.type == UserInteractionType.permission);

    testWidgets("flag on: Share grants permission without a dialog", (
      tester,
    ) async {
      await pumpSession(
        tester,
        flag: _Flag.on,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      await tester.tap(_shareButton);
      await tester.pump();

      expect(find.byType(DisclosurePermissionConfirmDialog), findsNothing);
      expect(permissions(), hasLength(1));
      expect(permissions().single.payload!["granted"], isTrue);
    });

    testWidgets("flag off: Share data still asks in a dialog first", (
      tester,
    ) async {
      await pumpSession(
        tester,
        flag: _Flag.off,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      await tester.tap(_shareButton);
      await tester.pumpAndSettle();

      expect(find.byType(DisclosurePermissionConfirmDialog), findsOneWidget);
      expect(permissions(), isEmpty);
    });

    testWidgets("flag on: signing still asks in a dialog first", (
      tester,
    ) async {
      await pumpSession(
        tester,
        flag: _Flag.on,
        session: _session(
          type: SessionType.signature,
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      await tester.tap(_shareButton);
      await tester.pumpAndSettle();

      expect(find.byType(DisclosurePermissionConfirmDialog), findsOneWidget);
      expect(permissions(), isEmpty);
    });
  });

  group("BoldMarkersText", () {
    testWidgets("sets the marked words in bold", (tester) async {
      await pumpAndLoadLocales(
        tester,
        _app(
          home: const Scaffold(
            body: BoldMarkersText(
              "disclosure_permission.share_v2.trust_known",
              translationParams: {"requestorName": "Gemeente"},
            ),
          ),
          overrides: [],
        ),
      );

      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(BoldMarkersText),
          matching: find.byType(Text),
        ),
      );
      final span = text.textSpan! as TextSpan;
      final parts = span.children!.cast<TextSpan>();

      expect(parts.map((p) => p.text), ["", "Gemeente", " is known to us."]);
      expect(parts[0].style, isNull);
      expect(parts[1].style!.fontWeight, FontWeight.w700);
      expect(parts[2].style, isNull);
    });

    testWidgets("a name with the marker cannot change what is bold", (
      tester,
    ) async {
      await pumpAndLoadLocales(
        tester,
        _app(
          home: const Scaffold(
            body: BoldMarkersText(
              "disclosure_permission.share_v2.trust_known",
              translationParams: {"requestorName": "A**B"},
            ),
          ),
          overrides: [],
        ),
      );

      expect(
        find.text("AB is known to us.", findRichText: true),
        findsOneWidget,
      );
    });
  });
}

class _RecordingBridge extends IrmaBridge {
  final dispatched = <Event>[];

  @override
  void dispatch(Event event) => dispatched.add(event);
}
