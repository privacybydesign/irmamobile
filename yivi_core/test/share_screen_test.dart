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
import "package:yivi_core/src/screens/session/widgets/disclosure_make_choice_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_permission_confirm_dialog.dart";
import "package:yivi_core/src/screens/session/widgets/share_credential_card.dart";
import "package:yivi_core/src/screens/session/widgets/share_trust_bar.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/bold_markers_text.dart";
import "package:yivi_core/src/widgets/chevron.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";
import "package:yivi_core/src/widgets/irma_avatar.dart";
import "package:yivi_core/src/widgets/translated_text.dart";
import "package:yivi_core/src/widgets/yivi_themed_button.dart";

import "support/pump_translated.dart";

const _sessionId = 1;
const _detailsPath = "/home/credentials_details";
const _bsnCredentialId = "pbdf.gemeente.personalData";

final _shareButton = find.byKey(const Key("bottom_bar_primary"));
final _confirmButton = find.byKey(const Key("share_check_confirm"));
final _declineButton = find.byKey(const Key("share_check_decline"));
final _progressLine = find.byKey(const Key("share_check_progress"));
final _issuerBand = find.byKey(const Key("share_card_issuer_band"));
final _cardValues = find.byKey(const Key("share_card_values"));
final _closeButton = find.byKey(const Key("share_close_button"));
final _sheet = find.byKey(const Key("share_check_sheet"));
final _handle = find.byKey(const Key("share_check_handle"));
final _badge = find.byKey(const Key("share_check_badge"));
final _shareCircle = find
    .ancestor(
      of: find.byIcon(Icons.ios_share),
      matching: find.byType(Container),
    )
    .first;

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
    await pumpTranslated(
      tester,
      _app(
        home: _Overview(confirmed: confirmed, dismissed: dismissed),
        overrides: [_flag(flag), _sessionOverride(session)],
        openedDetails: openedDetails,
      ),
    );
    await tester.pumpAndSettle();
  }

  group("share screen with the flag on", () {
    testWidgets("is on the light blue page", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      final scaffold = tester.widget<Scaffold>(
        find.ancestor(
          of: find.byType(ShareCredentialCard),
          matching: find.byType(Scaffold),
        ),
      );
      final theme = IrmaTheme.of(
        tester.element(find.byType(ShareCredentialCard)),
      );
      expect(scaffold.backgroundColor, theme.backgroundTertiary);
    });

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
      expect(_closeButton, findsOneWidget);

      await tester.tap(_closeButton);
      await tester.pump();

      expect(dismissed, hasLength(1));
    });

    testWidgets("K1: the close button is 48 px, 8 px from the corner, and says "
        "it does not share", (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      expect(tester.getRect(_closeButton), const Rect.fromLTWH(334, 8, 48, 48));
      expect(tester.getSemantics(_closeButton).label, "Don't share and close");
      expect(
        tester.widget<Icon>(find.byIcon(Icons.close)).color,
        IrmaTheme.of(tester.element(_closeButton)).dark,
      );
      semantics.dispose();
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
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
    });

    testWidgets("K1: two 56 px circles overlap by 8 px, above a centred "
        "26 px heading", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      final theme = IrmaTheme.of(tester.element(_shareCircle));
      final share = tester.getRect(_shareCircle);
      final requestor = tester.getRect(find.byType(IrmaAvatar));
      expect(share.size, const Size(56, 56));
      expect(requestor.size, const Size(56, 56));
      expect(share.top, 48);
      expect(requestor.left, share.right - 8);
      expect(
        (tester.widget<Container>(_shareCircle).decoration! as BoxDecoration)
            .color,
        theme.tertiary,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.ios_share)).color,
        theme.link,
      );
      expect(share.left, (390 - 104) / 2);

      final title = find.byType(BoldMarkersText).first;
      final style = tester.widget<BoldMarkersText>(title).style!;
      expect(style.fontSize, 26);
      expect(style.height, 34 / 26);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.color, theme.dark);
      expect(tester.widget<BoldMarkersText>(title).textAlign, TextAlign.center);
      expect(tester.getRect(title).top, requestor.bottom + 20);
    });

    testWidgets("K4: an unknown requestor gets a globe in a white circle", (
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

      final theme = IrmaTheme.of(tester.element(_shareCircle));
      final globe = find.ancestor(
        of: find.byIcon(Icons.language),
        matching: find.byType(Container),
      );
      final decoration =
          tester.widget<Container>(globe.first).decoration! as BoxDecoration;
      expect(find.byType(IrmaAvatar), findsNothing);
      expect(tester.getSize(globe.first), const Size(56, 56));
      expect(decoration.color, theme.light);
      expect(decoration.shape, BoxShape.circle);
      expect(
        decoration.border,
        Border.all(color: theme.neutralLight, width: 2),
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.language)).color,
        theme.neutralDark,
      );
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

    testWidgets("a credential that cannot be changed has a plain issuer band", (
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

      expect(
        find.descendant(of: _issuerBand, matching: find.byType(Chevron)),
        findsNothing,
      );
      await tester.tap(_issuerBand);
      await tester.pumpAndSettle();

      expect(opened, isEmpty);
      expect(find.byType(DisclosureMakeChoiceScreen), findsNothing);
    });

    testWidgets("K1: the values sit on a white card with a 12 px radius and "
        "the board's shadow", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      final decoration =
          tester.widget<DecoratedBox>(_cardValues).decoration as BoxDecoration;
      final theme = IrmaTheme.of(tester.element(_issuerBand));
      expect(decoration.color, theme.light);
      expect(decoration.borderRadius, BorderRadius.circular(12));
      expect(decoration.boxShadow, const [
        BoxShadow(
          color: Color(0x24000000),
          offset: Offset(0, 2),
          blurRadius: 6,
        ),
      ]);
      expect(
        tester.getRect(_issuerBand).top,
        tester.getRect(_cardValues).bottom,
      );
    });

    testWidgets("K1: a card is 128 px of values and a 45 px band, and the "
        "cards are 20 px apart", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([
              _instance(
                attributes: [
                  _attribute("first", "Voornamen", "Rosanne"),
                  _attribute("last", "Achternaam", "de Vries"),
                ],
              ),
            ]),
            _choice([_instance(credentialId: "pbdf.pbdf.email")]),
          ],
        ),
      );

      final values = tester.getRect(_cardValues.first);
      final band = tester.getRect(_issuerBand.first);
      expect(values.left, 16);
      expect(values.width, 358);
      expect(values.height, 14 + 20 + 24 + 12 + 20 + 24 + 14);
      expect(band.left, 16);
      expect(band.width, 358);
      expect(band.height, 12 + 20 + 12 + 1);
      expect(tester.getRect(_cardValues.last).top, band.bottom + 20);
      expect(
        values.top,
        48 +
            56 +
            20 +
            tester.getSize(find.byType(BoldMarkersText).first).height +
            20,
      );
    });

    testWidgets("a screen reader reads the values before the issuer band", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      final labels = tester.semantics
          .simulatedAccessibilityTraversal()
          .map((node) => node.label)
          .toList();
      expect(
        labels.indexWhere((l) => l.contains("Jansen")),
        lessThan(labels.indexWhere((l) => l.contains("Certified by RvIG"))),
      );
      expect(labels.indexWhere((l) => l.contains("Jansen")), isNonNegative);
      semantics.dispose();
    });

    testWidgets("K1: label 14/20 grey, value 17/24 semibold black", (
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

      final theme = IrmaTheme.of(tester.element(_issuerBand));
      final label = tester.widget<Text>(find.text("Surname")).style!;
      final value = tester.widget<Text>(find.text("Jansen")).style!;
      expect(label.fontSize, 14);
      expect(label.height, 20 / 14);
      expect(label.color, theme.neutralExtraDark);
      expect(value.fontSize, 17);
      expect(value.height, 24 / 17);
      expect(value.fontWeight, FontWeight.w600);
      expect(value.color, theme.dark);
    });

    testWidgets("K1: the band is a 14 px line with the issuer in bold, on "
        "#F5F3F1 with a #E3DDD9 border", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      final band = tester.widget<DecoratedBox>(
        find
            .ancestor(of: _issuerBand, matching: find.byType(DecoratedBox))
            .first,
      );
      final decoration = band.decoration as BoxDecoration;
      const edge = BorderSide(color: Color(0xFFE3DDD9));
      expect(decoration.color, const Color(0xFFF5F3F1));
      expect(
        decoration.borderRadius,
        const BorderRadius.vertical(bottom: Radius.circular(12)),
      );
      expect(
        decoration.border,
        const Border(left: edge, right: edge, bottom: edge),
      );

      final text = tester.widget<Text>(find.text("Certified by RvIG"));
      expect(text.style!.fontSize, 14);
      expect(text.style!.height, 20 / 14);
      expect(text.style!.fontWeight, FontWeight.w400);
      expect(
        (text.textSpan! as TextSpan).children!
            .whereType<TextSpan>()
            .where((s) => s.style?.fontWeight == FontWeight.w700)
            .map((s) => s.text),
        ["RvIG"],
      );
    });

    testWidgets("K1: the chevron is 18 px and 12 px from the edge", (
      tester,
    ) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance(), _instance(credentialId: "other")]),
          ],
        ),
      );

      final chevron = find.descendant(
        of: _issuerBand,
        matching: find.byType(Chevron),
      );
      final icon = tester.widget<Icon>(
        find.descendant(of: chevron, matching: find.byType(Icon)),
      );
      expect(icon.size, 18);
      expect(
        icon.color,
        IrmaTheme.of(tester.element(chevron)).neutralExtraDark,
      );
      expect(tester.getRect(chevron).right, 16 + 358 - 12 - 1);
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

    testWidgets("a choice between credentials is changed from the issuer "
        "band, without a separate button", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance(), _instance(credentialId: "pbdf.pbdf.idcard")]),
          ],
        ),
      );

      expect(find.text("Change choice"), findsNothing);
      expect(
        find.descendant(of: _issuerBand, matching: find.byType(Chevron)),
        findsOneWidget,
      );

      await tester.tap(_issuerBand);
      await tester.pumpAndSettle();

      expect(find.byType(DisclosureMakeChoiceScreen), findsOneWidget);
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

    testWidgets("K1: the link sits at the end of the row, in 16/22 text", (
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

      final theme = IrmaTheme.of(tester.element(find.byType(ShareTrustBar)));
      final bar = tester.getRect(find.byType(ShareTrustBar));
      final link = tester.getRect(find.text("What does this mean?"));
      final text = tester.getRect(find.byType(BoldMarkersText).last);
      expect(bar.left, 16);
      expect(bar.width, 358);
      expect(link.right, bar.right - 16);
      expect(link.left, greaterThan(text.right));
      expect(link.center.dy, bar.center.dy);

      final linkStyle = tester
          .widget<Text>(find.text("What does this mean?"))
          .style!;
      expect(linkStyle.fontSize, 16);
      expect(linkStyle.height, 22 / 16);
      expect(linkStyle.fontWeight, FontWeight.w400);
      expect(linkStyle.decoration, TextDecoration.underline);
      expect(linkStyle.color, theme.link);
      expect(
        tester
            .widget<BoldMarkersText>(find.byType(BoldMarkersText).last)
            .style!
            .height,
        22 / 16,
      );
    });

    testWidgets("a long link wraps at half the bar instead of overflowing", (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.text("What does this mean?")).width,
        lessThanOrEqualTo(358 / 2),
      );
    });

    testWidgets("K4: the unknown bar is the error surface with the same row", (
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

      final bar = tester.getRect(find.byType(ShareTrustBar));
      final link = tester.getRect(find.text("What does this mean?"));
      expect(link.right, bar.right - 16);
      expect(link.center.dy, bar.center.dy);
    });

    testWidgets("K1: the footer is a white bar with a 52 px button, 12 px "
        "below the trust bar and 32 px above the edge", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_instance()]),
          ],
        ),
      );

      final button = tester.getRect(_shareButton);
      final bar = tester.getRect(find.byType(ShareTrustBar));
      expect(button, const Rect.fromLTWH(16, 844 - 32 - 52, 358, 52));
      expect(bar.bottom, button.top - 12);
      expect(bar.top, 844 - 32 - 52 - 12 - bar.height);

      final footer = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.byType(ShareTrustBar),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = footer.decoration as BoxDecoration;
      expect(decoration.color, Colors.white);
      expect(decoration.boxShadow!.single.offset, const Offset(0, -1));
      expect(decoration.boxShadow!.single.blurRadius, 6);
      expect(decoration.boxShadow!.single.color, const Color(0xFFE0E0E0));
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
      expect(find.byIcon(Icons.gpp_maybe_outlined), findsOneWidget);
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
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
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

    testWidgets("K3: the sheet is white with a 16 px top radius, a handle "
        "and a 45% scrim", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_bsnInstance()]),
          ],
        ),
      );

      await _openSheet(tester);

      final sheet = tester.getRect(_sheet);
      final handle = tester.getRect(_handle);
      final decoration =
          tester.widget<Container>(_sheet).decoration! as BoxDecoration;
      final theme = IrmaTheme.of(tester.element(_sheet));
      expect(decoration.color, theme.light);
      expect(
        decoration.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(16)),
      );
      expect(sheet.left, 0);
      expect(sheet.right, 390);
      expect(sheet.bottom, 844);
      expect(handle.size, const Size(40, 4));
      expect(handle.top, sheet.top + 12);
      expect(handle.center.dx, 195);
      expect(
        (tester.widget<Container>(_handle).decoration! as BoxDecoration).color,
        theme.neutralLight,
      );
      expect(
        tester
            .widget<AnimatedModalBarrier>(
              find.byType(AnimatedModalBarrier).last,
            )
            .color
            .value,
        Colors.black.withValues(alpha: 0.45),
      );
    });

    testWidgets("K3: a 52 px amber badge, a 22 px heading and the text sit "
        "20 px from the edge", (tester) async {
      await pumpOverview(
        tester,
        session: _session(
          choices: [
            _choice([_bsnInstance()]),
          ],
        ),
      );

      await _openSheet(tester);

      final handle = tester.getRect(_handle);
      final badge = tester.getRect(_badge);
      final title = find.text("You are sharing your BSN");
      final body = find.textContaining("Your citizen service number");
      expect(badge, Rect.fromLTWH(20, handle.bottom + 14 + 8, 52, 52));
      expect(
        (tester.widget<Container>(_badge).decoration! as BoxDecoration).color,
        const Color(0xFFFDF1DC),
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.gpp_maybe_outlined)).color,
        const Color(0xFF7A4B00),
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.gpp_maybe_outlined)).size,
        26,
      );

      final titleStyle = tester.widget<Text>(title).style!;
      expect(titleStyle.fontSize, 22);
      expect(titleStyle.height, 30 / 22);
      expect(titleStyle.fontWeight, FontWeight.w700);
      expect(
        titleStyle.color,
        IrmaTheme.of(tester.element(title)).neutralExtraDark,
      );
      expect(tester.getRect(title).left, 20);
      expect(tester.getRect(title).top, badge.bottom + 14);
      expect(tester.getRect(body).left, 20);
      expect(tester.getRect(body).top, tester.getRect(title).bottom + 14);
      expect(tester.widget<Text>(body).textAlign, isNull);

      final style = tester.widget<Text>(body).style!;
      expect(style.fontSize, 16);
      expect(style.height, 24 / 16);
    });

    testWidgets("K5: the unknown party badge is the error surface with a red "
        "question mark", (tester) async {
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

      await _openSheet(tester);

      final theme = IrmaTheme.of(tester.element(_sheet));
      expect(
        (tester.widget<Container>(_badge).decoration! as BoxDecoration).color,
        theme.errorSurface,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.help_outline)).color,
        theme.error,
      );
    });

    testWidgets("K3: two 52 px buttons, 8 px apart, 32 px above the edge", (
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

      final confirm = tester.getRect(_confirmButton);
      final decline = tester.getRect(_declineButton);
      final body = tester.getRect(find.textContaining("Your citizen service"));
      expect(confirm.size, const Size(350, 52));
      expect(confirm.left, 20);
      expect(confirm.top, body.bottom + 14 + 6);
      expect(decline.top, confirm.bottom + 8);
      expect(decline.size, const Size(350, 52));
      expect(decline.bottom, 844 - 32);

      final outline = tester.widget<Ink>(
        find.descendant(of: _declineButton, matching: find.byType(Ink)),
      );
      final border = (outline.decoration! as BoxDecoration).border! as Border;
      expect(border.top.width, 1);
      expect(
        border.top.color,
        IrmaTheme.of(tester.element(_sheet)).neutralExtraDark,
      );
      expect(
        tester
            .widget<TranslatedText>(
              find.descendant(
                of: _declineButton,
                matching: find.byType(TranslatedText),
              ),
            )
            .style!
            .fontSize,
        17,
      );
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
        tester
            .widget<ColorFiltered>(
              find.descendant(
                of: _confirmButton,
                matching: find.byType(ColorFiltered),
              ),
            )
            .colorFilter,
        ColorFilter.mode(Colors.white.withAlpha(102), BlendMode.modulate),
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
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: _progressLine,
                    matching: find.byType(Positioned),
                  )
                  .first,
            )
            .height,
        3,
      );

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
      while (_isDisabled(tester)) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(opacity(), closeTo(0.4, 0.001));

      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity(), allOf(greaterThan(0.4), lessThan(1)));

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

  group("shared widgets without the share screen options", () {
    testWidgets("keep the sizes the app has always used", (tester) async {
      _usePhoneScreen(tester);
      await pumpTranslated(
        tester,
        _app(
          home: Scaffold(
            body: Column(
              children: [
                const YiviThemedButton(
                  key: Key("outlined"),
                  label: "ui.next",
                  style: YiviButtonStyle.outlined,
                ),
                const YiviThemedButton(key: Key("disabled"), label: "ui.next"),
                YiviCredentialCardAttributeList([
                  _attribute("surname", "Surname", "Jansen"),
                ]),
              ],
            ),
          ),
          overrides: const [],
        ),
      );
      await tester.pumpAndSettle();

      final ink = tester.widget<Ink>(
        find.descendant(
          of: find.byKey(const Key("outlined")),
          matching: find.byType(Ink),
        ),
      );
      expect(
        ((ink.decoration! as BoxDecoration).border! as Border).top.width,
        1.7,
      );
      expect(tester.getSize(find.byKey(const Key("outlined"))).height, 50);
      expect(
        tester
            .widget<ColorFiltered>(
              find.descendant(
                of: find.byKey(const Key("disabled")),
                matching: find.byType(ColorFiltered),
              ),
            )
            .colorFilter,
        ColorFilter.mode(Colors.white.withAlpha(128), BlendMode.modulate),
      );

      final label = tester.widget<Text>(find.text("Surname")).style!;
      final value = tester.widget<Text>(find.text("Jansen")).style!;
      expect(label.height, isNull);
      expect(value.height, isNull);
      expect(value.fontSize, 16);
      expect(
        find.ancestor(
          of: find.text("Surname"),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Padding &&
                w.padding == const EdgeInsets.only(top: 4, bottom: 4),
          ),
        ),
        findsOneWidget,
      );
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
      await pumpTranslated(
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
      await tester.pumpAndSettle();
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
      await pumpTranslated(
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
      await tester.pumpAndSettle();

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
      await pumpTranslated(
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
      await tester.pumpAndSettle();

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
