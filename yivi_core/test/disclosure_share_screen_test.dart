import "dart:async";
import "dart:math";

import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/schemaless/session_user_interaction.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/email_issuance_provider.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/nested_issuance_host_provider.dart";
import "package:yivi_core/src/providers/schemaless_credential_store_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_instruction_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/passport_mrz_manual_entry_screen.dart";
import "package:yivi_core/src/screens/session/widgets/change_choice_sheet.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issue_sheet_progress.dart";
import "package:yivi_core/src/screens/session/widgets/session_columns.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/card_tile.dart";
import "package:yivi_core/src/widgets/credential_card/credential_type_thumbnail.dart";
import "package:yivi_core/src/widgets/document_flow_footer.dart";
import "package:yivi_core/src/widgets/glass/sheet_action_row.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";
import "package:yivi_core/src/widgets/irma_bottom_bar_base.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";
import "support/pump_translated.dart";

const _sessionId = 1;
const _detailsPath = "/home/add_data/details";
const _future = 4102444800;

class _NoWallet extends SchemalessCredentialOrderController {
  @override
  Future<List<Credential>> build() async => const [];
}

TrustedParty _party(String name) =>
    TrustedParty(id: name, name: name, url: null, parent: null, verified: true);

CredentialDescriptor _descriptor(
  String id,
  String name, {
  List<Attribute> attributes = const [],
}) => CredentialDescriptor(
  credentialId: id,
  name: name,
  issuer: _party("Issuer"),
  category: null,
  attributes: attributes,
  issueURL: "https://www.issuer.example/$id",
);

SelectableCredentialInstance _instance(
  String id,
  String name,
  String value, {
  bool revoked = false,
  int? batch,
  String issuer = "RvIG",
}) => SelectableCredentialInstance(
  credentialId: id,
  hash: "hash-$id-$value",
  name: name,
  issuer: _party(issuer),
  format: batch == null ? CredentialFormat.idemix : CredentialFormat.msoMdoc,
  attributes: [
    Attribute(
      claimPath: ["value"],
      displayName: "Value",
      value: AttributeValue(type: AttributeType.string, string: value),
    ),
  ],
  revoked: revoked,
  revocationSupported: revoked,
  batchInstanceCountRemaining: batch,
  expiryDate: _future,
);

DisclosureBundle _bundle(SelectableCredentialInstance i) =>
    DisclosureBundle(credentials: [i]);

DisclosurePickOne _passportOrIdCard({bool optional = false}) =>
    DisclosurePickOne(
      optional: optional,
      ownedOptions: [
        _bundle(_instance("passport", "Passport", "Jansen")),
        _bundle(_instance("idcard", "ID card", "de Vries")),
      ],
    );

SessionState _session(
  List<DisclosurePickOne> choices, {
  SessionType type = SessionType.disclosure,
  String? message,
  List<Credential>? offered,
  TrustedParty? requestor,
}) => SessionState(
  id: _sessionId,
  protocol: "irma",
  type: type,
  status: SessionStatus.requestPermission,
  requestor: requestor ?? _party("Webshop Noord"),
  disclosurePlan: DisclosurePlan(disclosureChoicesOverview: choices),
  messageToSign: message,
  offeredCredentials: offered,
);

/// What the screen reported through its callbacks.
class _Calls {
  final shared = <List<DisclosureDisconSelection>>[];
  final obtained = <String>[];
  var closed = 0;
  var dismissed = 0;

  /// What the sheet sent to Go (for an issuance in it).
  final bridge = RecordingBridge();
  late final IrmaRepository repo;

  Iterable<SessionUserInteractionEvent> get interactions =>
      bridge.dispatched.whereType<SessionUserInteractionEvent>();
}

class _Screen extends ConsumerWidget {
  final _Calls calls;

  const _Screen(this.calls);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider(_sessionId)).value;
    if (session == null) return const SizedBox();
    return DisclosureShareScreen(
      session: session,
      onDismiss: () => calls.dismissed++,
      onClose: () => calls.closed++,
      onShare: calls.shared.add,
    );
  }
}

Future<_Calls> _pump(
  WidgetTester tester, {
  SessionState? session,
  Stream<SessionState>? sessions,
  Map<int, Stream<SessionState>> nested = const {},
  List<Override> overrides = const [],
  Size size = const Size(390, 844),
  FakeViewPadding? padding,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  if (padding != null) tester.view.padding = padding;
  addTearDown(tester.view.reset);
  final calls = _Calls();
  final repo = (await tester.runAsync(
    () async => IrmaRepository(
      client: calls.bridge,
      preferences: await freshPreferences(),
    ),
  ))!;
  addTearDown(() => tester.runAsync(repo.close));
  calls.repo = repo;
  final router = GoRouter(
    routes: [
      GoRoute(path: "/", builder: (_, _) => _Screen(calls)),
      GoRoute(
        path: _detailsPath,
        builder: (_, state) {
          calls.obtained.add(state.uri.queryParameters["credential"]!);
          return const Scaffold(body: Text("details"));
        },
      ),
    ],
  );
  await pumpTranslated(
    tester,
    ProviderScope(
      overrides: [
        sessionStateProvider(
          _sessionId,
        ).overrideWith((ref) => sessions ?? Stream.value(session!)),
        schemalessCredentialOrderControllerProvider.overrideWith(_NoWallet.new),
        irmaRepositoryProvider.overrideWithValue(repo),
        groupedCredentialStoreProvider.overrideWith(
          (ref) => Stream.value(const []),
        ),
        for (final MapEntry(key: id, value: states) in nested.entries)
          sessionStateProvider(id).overrideWith((ref) => states),
        ...overrides,
        // Where "Go to …" sends the user, recorded instead of opened.
        issuerOpenerProvider.overrideWithValue(
          (context, d, ref) async => calls.obtained.add(d.credentialId),
        ),
      ],
      // As in the app, the repository also as an inherited widget (which
      // handlePointer reads).
      child: IrmaRepositoryProvider(
        repository: repo,
        child: IrmaTheme(
          builder: (_) => MaterialApp.router(
            routerConfig: router,
            // As the app does: the core Material that the code fields (pinput)
            // look for.
            builder: (context, child) =>
                LegacyMaterialBridge(child: child ?? const SizedBox.shrink()),
            localizationsDelegates: [
              FlutterI18nDelegate(
                translationLoader: FileTranslationLoader(
                  basePath: "assets/locales",
                  forcedLocale: const Locale("en", "US"),
                ),
              ),
              ...GlobalMaterialLocalizations.delegates,
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return calls;
}

final _share = find.byKey(const Key("share_button"));

/// The hashes sent per pick-one.
List<List<String>> _hashes(List<DisclosureDisconSelection> sent) => [
  for (final d in sent) [for (final c in d.credentials) c.credentialHash],
];

void main() {
  testWidgets("the question, who asks, the values, and Share", (tester) async {
    final calls = await _pump(
      tester,
      session: _session([
        DisclosurePickOne(
          optional: false,
          ownedOptions: [
            _bundle(_instance("email", "Email", "s@werk.example")),
          ],
        ),
      ]),
    );

    // Who asks, as the subject: "Webshop Noord is asking for your data";
    // under it, exactly what they get.
    expect(find.text("Webshop Noord"), findsOneWidget);
    expect(find.text("Registered with Yivi"), findsOneWidget);
    expect(find.text("is asking for your data"), findsOneWidget);
    expect(
      find.text(
        "Below is exactly what they get. Nothing is sent until you press "
        "the share button.",
      ),
      findsOneWidget,
    );
    expect(find.text("YOU SHARE THIS"), findsOneWidget);
    // No large title any more.
    expect(find.text("Share your data with"), findsNothing);
    expect(find.text("s@werk.example"), findsOneWidget);
    // Only one option: nothing to change.
    expect(find.byKey(const Key("share_change_0")), findsNothing);
    expect(find.byKey(const Key("share_reason")), findsNothing);
    // Something is shared and nothing is missing: what stays private.
    expect(
      find.text(
        "Webshop Noord only gets what is above. Everything else stays on "
        "your phone.",
      ),
      findsOneWidget,
    );

    // The button is the consent: no dialog, the choices are sent at once.
    await tester.tap(
      find.descendant(
        of: _share,
        matching: find.text("Share with Webshop Noord"),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(_hashes(calls.shared.single), [
      ["hash-email-s@werk.example"],
    ]);
  });

  testWidgets("Change opens the sheet; a tap picks and closes", (tester) async {
    final calls = await _pump(tester, session: _session([_passportOrIdCard()]));

    expect(find.text("Jansen"), findsOneWidget);
    // The other choice, in a strip at the foot of the card.
    expect(find.text("You can also choose your ID card"), findsOneWidget);
    expect(find.text("Change choice"), findsOneWidget);
    await tester.tap(find.byKey(const Key("share_change_0")));
    await tester.pumpAndSettle();
    expect(find.text("Pick a card"), findsOneWidget);

    await tester.tap(find.byKey(const Key("sheet_owned_hash-idcard-de Vries")));
    await tester.pumpAndSettle();
    expect(find.text("Pick a card"), findsNothing);
    expect(find.text("de Vries"), findsOneWidget);
    expect(find.text("Jansen"), findsNothing);

    await tester.tap(_share);
    expect(_hashes(calls.shared.single), [
      ["hash-idcard-de Vries"],
    ]);
  });

  testWidgets("the sheet sends the user to get a card not in the app", (
    tester,
  ) async {
    final calls = await _pump(
      tester,
      session: _session([
        DisclosurePickOne(
          optional: false,
          ownedOptions: [_bundle(_instance("passport", "Passport", "Jansen"))],
          obtainableOptions: [_descriptor("idcard", "ID card")],
        ),
      ]),
    );

    await tester.tap(find.byKey(const Key("share_change_0")));
    await tester.pumpAndSettle();
    expect(find.text("NOT IN YOUR APP YET"), findsOneWidget);
    // An empty card: its name, its issuer, and Add on its edge.
    final add = find.byKey(const Key("sheet_add_idcard"));
    expect(find.descendant(of: add, matching: find.text("ID card")), findsOne);
    expect(find.descendant(of: add, matching: find.text("Issuer")), findsOne);
    expect(
      find.descendant(
        of: add,
        matching: find.byKey(const Key("empty_spot_add")),
      ),
      findsOne,
    );

    // First its details, step 1 of 3, as on the add-data page.
    await tester.tap(find.byKey(const Key("sheet_add_idcard")));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("add_data_details_issuer")), findsOneWidget);
    expect(
      find.byKey(const ValueKey(("issue_sheet_progress", 1, 3))),
      findsOneWidget,
    );
    expect(find.text("For Webshop Noord"), findsOneWidget);
    expect(find.byKey(const Key("add_data_disclosure_note")), findsOneWidget);
    expect(calls.obtained, isEmpty);

    // Then the website, with the sheet waiting for the user to come back.
    await tester.tap(find.byKey(const Key("sheet_go_button")));
    await tester.pumpAndSettle();
    expect(calls.obtained, ["idcard"]);
    expect(find.byKey(const Key("disclosure_choice_sheet")), findsOneWidget);
    expect(
      find.byKey(const ValueKey(("issue_sheet_progress", 2, 3))),
      findsOneWidget,
    );
    expect(find.byKey(const Key("sheet_opened_note")), findsOneWidget);
    expect(find.text("Open again"), findsOneWidget);
  });

  group("optional data", () {
    testWidgets("starts faded; Share too includes it, Don't share leaves it "
        "out again", (tester) async {
      final calls = await _pump(
        tester,
        session: _session([_passportOrIdCard(optional: true)]),
      );

      // The card it would be, at half strength in a dashed edge.
      final ghost = find.byKey(const Key("share_add_optional_0"));
      expect(
        find.descendant(of: ghost, matching: find.text("Jansen")),
        findsOneWidget,
      );
      expect(find.text("Share too"), findsOneWidget);
      expect(find.byKey(const Key("share_slot_0")), findsNothing);
      expect(find.text("Share without data"), findsOneWidget);
      expect(
        find.text("Webshop Noord asks for nothing you must share."),
        findsOneWidget,
      );
      // Nothing is shared: no footnote.
      expect(find.byKey(const Key("share_footnote")), findsNothing);

      // Share too: included at once, no sheet.
      await tester.tap(ghost);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("disclosure_choice_sheet")), findsNothing);
      expect(find.byKey(const Key("share_slot_0")), findsOneWidget);
      expect(find.text("Share with Webshop Noord"), findsOneWidget);
      expect(find.text("You can also choose your ID card"), findsOneWidget);

      await tester.tap(find.byKey(const Key("share_remove_0")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("share_slot_0")), findsNothing);
      expect(find.byKey(const Key("share_add_optional_0")), findsOneWidget);

      await tester.tap(_share);
      expect(_hashes(calls.shared.single), [<String>[]]);
    });

    testWidgets("Change choice: another card for it, picked in the sheet", (
      tester,
    ) async {
      final calls = await _pump(
        tester,
        session: _session([_passportOrIdCard(optional: true)]),
      );
      await tester.tap(find.byKey(const Key("share_add_optional_0")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();
      expect(find.text("Add optional data"), findsOneWidget);
      await tester.tap(
        find.byKey(const Key("sheet_owned_hash-idcard-de Vries")),
      );
      await tester.pumpAndSettle();
      expect(find.text("de Vries"), findsOneWidget);

      await tester.tap(_share);
      expect(_hashes(calls.shared.single), [
        ["hash-idcard-de Vries"],
      ]);
    });

    testWidgets("not in the app: an empty spot; a card added for it is "
        "included once it arrives", (tester) async {
      final sessions = StreamController<SessionState>();
      addTearDown(sessions.close);
      DisclosurePickOne optional(List<SelectableCredentialInstance> owned) =>
          DisclosurePickOne(
            optional: true,
            ownedOptions: [for (final i in owned) _bundle(i)],
            obtainableOptions: [_descriptor("idcard", "ID card")],
          );
      sessions.add(_session([optional(const [])]));
      final calls = await _pump(tester, sessions: sessions.stream);

      final spot = find.byKey(const Key("share_add_optional_0"));
      expect(
        find.descendant(of: spot, matching: find.byType(CardTile)),
        findsOneWidget,
      );
      await tester.tap(spot);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await tester.pumpAndSettle();
      expect(calls.obtained, ["idcard"]);
      // Not included before the card is there (behind the sheet, which
      // waits for the user to come back).
      expect(find.byKey(const Key("share_slot_0")), findsNothing);

      sessions.add(
        _session([
          optional([_instance("idcard", "ID card", "de Vries")]),
        ]),
      );
      await tester.pumpAndSettle();

      // Included on the page under the sheet (not drawn while it is open).
      expect(
        find.byKey(const Key("share_slot_0"), skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text("de Vries", skipOffstage: false), findsOneWidget);
    });

    testWidgets("leaving the sheet without adding changes nothing", (
      tester,
    ) async {
      await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: true,
            ownedOptions: const [],
            obtainableOptions: [
              _descriptor("passport", "Passport"),
              _descriptor("idcard", "ID card"),
            ],
          ),
        ]),
      );

      await tester.tap(find.byKey(const Key("share_add_optional_0")));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key("disclosure_choice_sheet")),
          matching: find.byType(IrmaCloseButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key("share_add_optional_0")), findsOneWidget);
      expect(find.byKey(const Key("share_slot_0")), findsNothing);
    });
  });

  group("cards that cannot be shared", () {
    testWidgets("revoked: the reason, the button off, and the fix", (
      tester,
    ) async {
      final calls = await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: [
              _bundle(
                _instance("address", "Address", "Nijmegen", revoked: true),
              ),
            ],
            obtainableOptions: [_descriptor("address", "Address")],
          ),
        ]),
      );

      expect(find.text("Revoked"), findsOneWidget);
      expect(
        find.text("Renew your address first. Then you can share."),
        findsOneWidget,
      );
      // The note in a red strip, with Renew in it; no footnote yet.
      expect(find.byKey(const Key("shared_card_problem")), findsOneWidget);
      expect(find.text("Renew"), findsOneWidget);
      expect(find.byKey(const Key("share_footnote")), findsNothing);
      await tester.tap(_share);
      expect(calls.shared, isEmpty);

      // The fix opens the sheet straight on adding a new one: its details.
      await tester.tap(find.byKey(const Key("shared_card_fix")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("add_data_details_issuer")), findsOneWidget);
      expect(find.text("Address"), findsWidgets);
      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await tester.pumpAndSettle();
      expect(calls.obtained, ["address"]);
    });

    testWidgets("used up and not renewable in Yivi: Close", (tester) async {
      final calls = await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: [
              _bundle(
                _instance("pid", "PID", "Yes", batch: 0, issuer: "PID Issuer"),
              ),
            ],
          ),
        ]),
      );

      expect(find.text("Used up"), findsOneWidget);
      expect(
        find.text(
          "Webshop Noord needs a card you can't renew in Yivi. Ask PID Issuer for a new one.",
        ),
        findsOneWidget,
      );
      await tester.tap(find.text("Close"));
      expect(calls.closed, 1);
      expect(calls.shared, isEmpty);
    });
  });

  testWidgets("signing: its own question, the message and Sign and share", (
    tester,
  ) async {
    await _pump(
      tester,
      session: _session(
        [_passportOrIdCard()],
        type: SessionType.signature,
        message: "I agree to the rental agreement.",
      ),
    );

    expect(find.text("is asking you to sign something"), findsOneWidget);
    expect(
      find.text(
        "Below is exactly what they get. Nothing is sent until you press "
        "the sign button.",
      ),
      findsOneWidget,
    );
    expect(find.text("You sign this message"), findsOneWidget);
    expect(find.text("YOU SHARE THIS WITH YOUR SIGNATURE"), findsOneWidget);
    expect(find.text("Sign and share"), findsOneWidget);
  });

  testWidgets("a card in return: You receive, Share and add card", (
    tester,
  ) async {
    await _pump(
      tester,
      session: _session(
        [_passportOrIdCard()],
        type: SessionType.issuance,
        offered: [
          Credential(
            credentialId: "student",
            hash: "student",
            name: "Student card",
            issuer: _party("Radboud University"),
            credentialInstanceIds: const {CredentialFormat.idemix: "student"},
            batchInstanceCountsRemaining: const {},
            attributes: const [],
            revoked: false,
            revocationSupported: false,
            issueUrl: null,
          ),
        ],
      ),
    );

    expect(
      find.text("is asking for your data and gives you a card"),
      findsOneWidget,
    );
    expect(find.text("YOU GET THIS IN RETURN"), findsOneWidget);
    expect(find.text("Share and add card"), findsOneWidget);
  });

  group("a card not in the app yet", () {
    SessionState withPlan(
      List<DisclosurePickOne> choices,
      IssueDuringDisclosure plan,
    ) => SessionState(
      id: _sessionId,
      protocol: "irma",
      type: SessionType.disclosure,
      status: SessionStatus.requestPermission,
      requestor: _party("Webshop Noord"),
      disclosurePlan: DisclosurePlan(
        disclosureChoicesOverview: choices,
        issueDuringDisclosure: plan,
      ),
    );
    final email = DisclosurePickOne(
      optional: false,
      ownedOptions: [_bundle(_instance("email", "Email address", "a@b.nl"))],
    );

    testWidgets("is an empty spot; Share waits for it", (tester) async {
      final calls = await _pump(
        tester,
        session: _session([
          email,
          DisclosurePickOne(
            optional: false,
            ownedOptions: const [],
            obtainableOptions: [_descriptor("idcard", "ID card")],
          ),
        ]),
      );
      expect(find.byKey(const Key("share_slot_0")), findsOneWidget);
      expect(find.byKey(const Key("share_spot_1")), findsOneWidget);
      // One type: its issuer under its name.
      expect(
        find.descendant(
          of: find.byKey(const Key("share_spot_1")),
          matching: find.text("Issuer"),
        ),
        findsOneWidget,
      );
      expect(
        find.text("Add your ID card first. Then you can share."),
        findsOneWidget,
      );
      // A card is still missing: no footnote yet.
      expect(find.byKey(const Key("share_footnote")), findsNothing);
      await tester.tap(_share);
      await tester.pump();
      expect(calls.shared, isEmpty);
    });

    testWidgets("one way to get it: the spot looks like the card, with what "
        "it will share still empty", (tester) async {
      await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: const [],
            obtainableOptions: [
              _descriptor(
                "idcard",
                "ID card",
                attributes: [
                  Attribute(
                    claimPath: ["firstname"],
                    displayName: "First name",
                    requestedValue: AttributeValue(type: AttributeType.string),
                  ),
                  Attribute(
                    claimPath: ["lastname"],
                    displayName: "Last name",
                    requestedValue: AttributeValue(type: AttributeType.string),
                  ),
                  // Part of the type, but not asked for: no row.
                  Attribute(claimPath: ["bsn"], displayName: "BSN"),
                ],
              ),
            ],
          ),
        ]),
      );
      final spot = find.byKey(const Key("share_spot_0"));
      expect(
        find.descendant(of: spot, matching: find.byType(CardTile)),
        findsOne,
      );
      expect(find.descendant(of: spot, matching: find.text("Add")), findsOne);
      expect(
        find.descendant(of: spot, matching: find.text("First name")),
        findsOneWidget,
      );
      expect(
        find.descendant(of: spot, matching: find.text("Last name")),
        findsOneWidget,
      );
      expect(
        find.descendant(of: spot, matching: find.text("Not in your app yet")),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: spot, matching: find.text("BSN")),
        findsNothing,
      );
    });

    testWidgets("several ways: no rows yet, only the name and the hint", (
      tester,
    ) async {
      await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: const [],
            obtainableOptions: [
              _descriptor(
                "passport",
                "Passport",
                attributes: [
                  Attribute(
                    claimPath: ["firstname"],
                    displayName: "First name",
                    requestedValue: AttributeValue(type: AttributeType.string),
                  ),
                ],
              ),
              _descriptor(
                "idcard",
                "ID card",
                attributes: [
                  Attribute(
                    claimPath: ["nationality"],
                    displayName: "Nationality",
                    requestedValue: AttributeValue(
                      type: AttributeType.string,
                      string: "NLD",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ]),
      );
      final spot = find.byKey(const Key("share_spot_0"));
      expect(
        find.descendant(of: spot, matching: find.text("First name")),
        findsNothing,
      );
      expect(find.descendant(of: spot, matching: find.text("Add")), findsOne);

      // In the sheet each type is an empty card, as on the share screen:
      // what it would share, and what it must hold.
      await tester.tap(spot);
      await tester.pumpAndSettle();
      final passport = find.byKey(const Key("sheet_add_passport"));
      final idcard = find.byKey(const Key("sheet_add_idcard"));
      for (final card in [passport, idcard]) {
        expect(
          find.descendant(
            of: card,
            matching: find.byKey(const Key("empty_spot_add")),
          ),
          findsOne,
        );
      }
      expect(
        find.descendant(of: idcard, matching: find.text("Must be NLD")),
        findsOne,
      );
      expect(
        find.descendant(of: passport, matching: find.textContaining("Must be")),
        findsNothing,
      );
    });

    testWidgets("one way to get it: the spot opens its details at once", (
      tester,
    ) async {
      await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: const [],
            obtainableOptions: [_descriptor("idcard", "ID card")],
          ),
        ]),
      );
      await tester.tap(find.byKey(const Key("share_spot_0")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("disclosure_choice_sheet")), findsOneWidget);
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 1, 3))),
        findsOneWidget,
      );
      expect(find.byKey(const Key("sheet_go_button")), findsOneWidget);

      // Nothing before the details: no back button, and no swipe back.
      expect(find.bySemanticsLabel("Go back"), findsNothing);
      await tester.drag(
        find.byKey(const ValueKey(("issue_sheet_progress", 1, 3))),
        const Offset(300, 0),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 1, 3))),
        findsOneWidget,
      );
      expect(find.byKey(const Key("disclosure_choice_sheet")), findsOneWidget);

      // Close is the way out (it asks, as it does on the details).
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key("disclosure_choice_sheet")),
          matching: find.byType(IrmaCloseButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_stop_confirm")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("disclosure_choice_sheet")), findsNothing);
    });

    testWidgets("several ways: which one to add first", (tester) async {
      await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: const [],
            obtainableOptions: [
              _descriptor("passport", "Passport"),
              _descriptor("idcard", "ID card"),
            ],
          ),
        ]),
      );
      // The types as small cards; the name lists them, the choice is made
      // when adding.
      final spot = find.byKey(const Key("share_spot_0"));
      expect(
        find.descendant(of: spot, matching: find.text("Passport or ID card")),
        findsOneWidget,
      );
      expect(find.text("You pick one when adding"), findsOneWidget);
      expect(
        find.descendant(
          of: spot,
          matching: find.byType(CredentialTypeThumbnail),
        ),
        findsNWidgets(2),
      );
      expect(
        find.text("Add your passport or ID card first. Then you can share."),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key("share_spot_0")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("sheet_add_passport")), findsOneWidget);
      expect(find.byKey(const Key("sheet_add_idcard")), findsOneWidget);
    });

    testWidgets("nothing to add it from: Close, and where to get it", (
      tester,
    ) async {
      final calls = await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: const [],
            obtainableOptions: [
              CredentialDescriptor(
                credentialId: "voting",
                name: "Voting card",
                issuer: _party("Demo Voting Card Issuer"),
                category: null,
                attributes: const [],
                issueURL: null,
              ),
            ],
          ),
        ]),
      );
      expect(
        find.text(
          "Yivi can't add voting card. Get it from Demo Voting Card Issuer "
          "first, then scan the QR code again.",
        ),
        findsOneWidget,
      );
      await tester.tap(_share);
      await tester.pump();
      expect(calls.closed, 1);
    });

    testWidgets("a card with the wrong value: what was added, what is needed", (
      tester,
    ) async {
      await _pump(
        tester,
        session: withPlan(
          [
            DisclosurePickOne(
              optional: false,
              ownedOptions: const [],
              obtainableOptions: [
                CredentialDescriptor(
                  credentialId: "ideal",
                  name: "iDEAL",
                  issuer: _party("Issuer"),
                  category: null,
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
                  issueURL: "https://www.issuer.example/ideal",
                ),
              ],
            ),
          ],
          IssueDuringDisclosure(
            steps: const [],
            wrongCredentialIssued: testCredential(
              type: "ideal",
              hash: "wrong-ideal",
              name: "iDEAL",
              attributes: [
                Attribute(
                  claimPath: ["bic"],
                  displayName: "BIC",
                  value: AttributeValue(
                    type: AttributeType.string,
                    string: "INGBNL2A",
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        find.text("You added INGBNL2A, needed RABONL2U. Tap to add it again."),
        findsOneWidget,
      );
      // The value it must have, in the spot's row for that field.
      final spot = find.byKey(const Key("share_spot_0"));
      expect(
        find.descendant(of: spot, matching: find.text("BIC")),
        findsOneWidget,
      );
      expect(
        find.descendant(of: spot, matching: find.text("Must be RABONL2U")),
        findsOneWidget,
      );
    });

    testWidgets("once added: in its place, added and selected", (tester) async {
      await _pump(
        tester,
        session: withPlan(
          [email],
          IssueDuringDisclosure(
            steps: const [],
            issuedCredentialIds: const {"email": <String, dynamic>{}},
          ),
        ),
      );
      expect(find.byKey(const Key("share_slot_0")), findsOneWidget);
      expect(find.byKey(const Key("shared_card_new")), findsOneWidget);
      expect(find.text("New"), findsOneWidget);
    });

    testWidgets("four types: three small cards and +1", (tester) async {
      await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: const [],
            obtainableOptions: [
              _descriptor("passport", "Passport"),
              _descriptor("idcard", "ID card"),
              _descriptor("licence", "Driving licence"),
              _descriptor("personal", "Personal data"),
            ],
          ),
        ]),
      );
      final spot = find.byKey(const Key("share_spot_0"));
      expect(
        find.descendant(
          of: spot,
          matching: find.text(
            "Passport, ID card, driving licence or personal data",
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: spot,
          matching: find.byType(CredentialTypeThumbnail),
        ),
        findsNWidgets(3),
      );
      expect(find.text("+1"), findsOneWidget);
    });
  });

  testWidgets("tablet: the question, who asks and the footnote left, what "
      "is shared right", (tester) async {
    // A 13" iPad held upright; sideways a tablet has the phone's panel.
    await _pump(
      tester,
      session: _session([_passportOrIdCard()]),
      size: const Size(1032, 1376),
    );
    expect(find.byType(SessionColumns), findsOneWidget);
    final slot = tester.getRect(find.byKey(const Key("share_slot_0")));
    for (final left in ["session_requestor_header", "share_footnote"]) {
      expect(
        tester.getRect(find.byKey(Key(left))).right,
        lessThan(slot.left),
        reason: left,
      );
    }
  });

  group("the Change sheet", () {
    testWidgets("another of a kind you have comes first", (tester) async {
      await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: [
              _bundle(
                _instance("email", "Email address", "sanne@devries.example"),
              ),
            ],
            obtainableOptions: [
              _descriptor("mobile", "Mobile number"),
              _descriptor("email", "Email address"),
            ],
          ),
        ]),
      );
      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();

      final email = tester.getTopLeft(find.byKey(const Key("sheet_add_email")));
      final mobile = tester.getTopLeft(
        find.byKey(const Key("sheet_add_mobile")),
      );
      expect(email.dy, lessThan(mobile.dy));
      expect(find.text("Another email address"), findsOneWidget);
      expect(find.text("Mobile number"), findsOneWidget);
      expect(find.text("NOT IN YOUR APP YET"), findsOneWidget);
    });

    testWidgets("the outline goes to the card a finger is on", (tester) async {
      await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: [
              _bundle(_instance("passport", "Passport", "Jansen")),
            ],
            obtainableOptions: [_descriptor("idcard", "ID card")],
          ),
        ]),
      );
      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();

      final owned = find.byKey(const Key("sheet_owned_hash-passport-Jansen"));
      final add = find.byKey(const Key("sheet_add_idcard"));
      Finder outlineIn(Finder card) => find.descendant(
        of: card,
        matching: find.byKey(const Key("card_tile_outline")),
      );
      expect(outlineIn(owned), findsOne);
      expect(outlineIn(add), findsNothing);

      // Pressed: the empty card has it, the one in use does not.
      final gesture = await tester.startGesture(tester.getCenter(add));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(outlineIn(add), findsOne);
      expect(outlineIn(owned), findsNothing);

      // Moved off to scroll: back on the card in use.
      await gesture.moveBy(const Offset(0, -60));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(outlineIn(owned), findsOne);
      expect(outlineIn(add), findsNothing);
    });

    testWidgets("cards of one type: which one, told apart by value", (
      tester,
    ) async {
      await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: [
              _bundle(_instance("email", "Email address", "s@werk.example")),
              _bundle(
                _instance("email", "Email address", "sanne@devries.example"),
              ),
            ],
            obtainableOptions: [_descriptor("email", "Email address")],
          ),
        ]),
      );
      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();

      expect(find.text("Pick a card"), findsOneWidget);
      expect(find.text("ALREADY IN YOUR APP"), findsOneWidget);
      expect(find.text("sanne@devries.example"), findsOneWidget);
      expect(find.text("Another email address"), findsOneWidget);
    });

    testWidgets("the current card is the checked radio", (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, session: _session([_passportOrIdCard()]));
      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(
          find.byKey(const Key("sheet_owned_hash-passport-Jansen")),
        ),
        isSemantics(
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(
          find.byKey(const Key("sheet_owned_hash-idcard-de Vries")),
        ),
        isSemantics(
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: false,
          isButton: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets("sits on the bottom edge, the chosen card shared as a hero", (
      tester,
    ) async {
      await _pump(tester, session: _session([_passportOrIdCard()]));
      Object heroTagOf(Finder f) => tester
          .widget<Hero>(find.ancestor(of: f, matching: find.byType(Hero)).first)
          .tag;
      final slotTag = heroTagOf(find.byKey(const Key("share_slot_0")));

      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byKey(const Key("glass_sheet"))).bottom,
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      );
      // The card in the sheet has every value it would share. (The one on
      // the share screen is hidden while its hero is in the sheet.)
      expect(
        find.descendant(
          of: find.byKey(const Key("sheet_owned_hash-passport-Jansen")),
          matching: find.text("Jansen"),
        ),
        findsOneWidget,
      );
      expect(
        heroTagOf(find.byKey(const Key("sheet_owned_hash-passport-Jansen"))),
        slotTag,
      );
    });

    testWidgets("the picked card flies back into the overview", (tester) async {
      await _pump(tester, session: _session([_passportOrIdCard()]));
      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();
      final picked = find.byKey(const Key("sheet_owned_hash-idcard-de Vries"));
      final from = tester
          .getRect(find.descendant(of: picked, matching: find.text("de Vries")))
          .top;

      await tester.tap(picked);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      // Mid-flight: the one card showing the new choice is on its way.
      final flying = tester.getRect(find.text("de Vries")).top;

      await tester.pumpAndSettle();
      final to = tester.getRect(find.text("de Vries")).top;
      expect(flying, inInclusiveRange(min(from, to), max(from, to)));
      expect(flying, isNot(closeTo(from, 1)));
      expect(flying, isNot(closeTo(to, 1)));
    });

    testWidgets("adding is a subpage: swiped back, its button at the bottom", (
      tester,
    ) async {
      await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: [
              _bundle(_instance("passport", "Passport", "Jansen")),
            ],
            obtainableOptions: [_descriptor("idcard", "ID card")],
          ),
        ]),
      );
      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_add_idcard")));
      await tester.pumpAndSettle();

      // Pinned to the bottom of the sheet, not under the content.
      final sheet = tester.getRect(find.byKey(const Key("glass_sheet")));
      final button = tester.getRect(find.byKey(const Key("sheet_go_button")));
      expect(sheet.bottom - button.bottom, lessThan(40));

      // A short swipe springs back; a long one goes back to the choice.
      await tester.timedDragFrom(
        const Offset(40, 400),
        const Offset(80, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("sheet_go_button")), findsOneWidget);
      await tester.timedDragFrom(
        const Offset(40, 400),
        const Offset(300, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("sheet_go_button")), findsNothing);
      expect(find.text("Pick a card"), findsOneWidget);
    });

    testWidgets("back from adding returns to the choice", (tester) async {
      await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: [
              _bundle(_instance("passport", "Passport", "Jansen")),
            ],
            obtainableOptions: [_descriptor("idcard", "ID card")],
          ),
        ]),
      );
      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_add_idcard")));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel("Go back"));
      await tester.pumpAndSettle();

      expect(find.text("Pick a card"), findsOneWidget);
    });
  });

  group("adding a card in the sheet", () {
    const nestedId = 99;
    final idCard = testCredential(
      type: "idcard",
      hash: "issued-idcard",
      name: "ID card",
      issuerName: "Issuer",
    );
    SessionState issuance(SessionStatus status) => SessionState(
      id: nestedId,
      protocol: "irma",
      type: SessionType.issuance,
      status: status,
      requestor: _party("Issuer"),
      offeredCredentials: [idCard],
    );

    /// The sheet on the ID card's details, its website opened.
    Future<(_Calls, StreamController<SessionState>)> openWebsite(
      WidgetTester tester,
    ) async {
      final nested = StreamController<SessionState>();
      addTearDown(nested.close);
      final calls = await _pump(
        tester,
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: [
              _bundle(_instance("passport", "Passport", "Jansen")),
            ],
            obtainableOptions: [_descriptor("idcard", "ID card")],
          ),
        ]),
        nested: {nestedId: nested.stream},
      );
      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_add_idcard")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await tester.pumpAndSettle();
      return (calls, nested);
    }

    /// What the issuer's pointer does when the user comes back: the session
    /// starts and goes to the sheet waiting for it.
    void comeBack(WidgetTester tester) {
      final host = ProviderScope.containerOf(
        tester.element(find.byType(ChangeChoiceSheet)),
      ).read(nestedIssuanceHostProvider);
      expect(host?.underlyingSessionId, _sessionId);
      host!.attach(nestedId);
    }

    testWidgets("back from the website, the issuance is step 3 in the sheet", (
      tester,
    ) async {
      final (calls, nested) = await openWebsite(tester);
      comeBack(tester);
      nested.add(issuance(SessionStatus.requestPermission));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 3, 3))),
        findsOneWidget,
      );
      expect(
        find.text("Do you want to add this data to your Yivi app?"),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key("sheet_issue_add")));
      await tester.pump();
      final granted = calls.interactions.last;
      expect(
        (granted.sessionId, granted.type),
        (nestedId, UserInteractionType.permission),
      );

      nested.add(issuance(SessionStatus.success));
      await tester.pumpAndSettle();
      expect(find.text("Added"), findsOneWidget);
      expect(find.text("Back to Webshop Noord"), findsOneWidget);
      // Done: no host waits any more, and closing does not ask.
      expect(
        ProviderScope.containerOf(
          tester.element(find.byType(ChangeChoiceSheet)),
        ).read(nestedIssuanceHostProvider),
        isNull,
      );

      // The card flies into its spot as the sheet closes.
      await tester.tap(find.byKey(const Key("sheet_back_to_request")));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key("sheet_flight_card")), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("sheet_flight_card")), findsNothing);
      expect(find.byKey(const Key("disclosure_choice_sheet")), findsNothing);
    });

    testWidgets("the PIN is a page in the sheet, with the lock", (
      tester,
    ) async {
      final (calls, nested) = await openWebsite(tester);
      comeBack(tester);
      nested.add(issuance(SessionStatus.requestPermission));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_issue_add")));
      await tester.pump();
      nested.add(issuance(SessionStatus.requestPin));
      await tester.pumpAndSettle();

      final sheet = find.byKey(const Key("disclosure_choice_sheet"));
      expect(
        find.descendant(
          of: sheet,
          matching: find.byKey(const Key("sheet_pin")),
        ),
        findsOneWidget,
      );
      // No full-screen PIN route; the lock above the pad, as on the full
      // screen PIN (the design's "PIN to share, in the sheet").
      // The one Scaffold is the page under the sheet (not drawn while the
      // sheet is open).
      expect(find.byType(Scaffold, skipOffstage: false), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 3, 3))),
        findsOneWidget,
      );

      for (final digit in ["1", "2", "3", "4", "5"]) {
        await tester.tap(find.text(digit).last);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump();
      expect(
        calls.interactions.map((e) => e.type),
        contains(UserInteractionType.enteredPin),
      );

      nested.add(issuance(SessionStatus.success));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("sheet_pin")), findsNothing);
      expect(find.text("Added"), findsOneWidget);
    });

    testWidgets("the progress stays put while the page scrolls", (
      tester,
    ) async {
      final (_, nested) = await openWebsite(tester);
      comeBack(tester);
      nested.add(issuance(SessionStatus.requestPermission));
      await tester.pumpAndSettle();
      final progress = find.byType(IssueSheetProgress);
      expect(progress, findsOneWidget);
      expect(
        find.ancestor(of: progress, matching: find.byType(Scrollable)),
        findsNothing,
      );
    });

    testWidgets("back on step 3: on the details again, to try again", (
      tester,
    ) async {
      final (calls, nested) = await openWebsite(tester);
      comeBack(tester);
      nested.add(issuance(SessionStatus.requestPermission));
      await tester.pumpAndSettle();
      // No Cancel: back (or close) is the way out.
      expect(find.byKey(const Key("sheet_issue_cancel")), findsNothing);

      await tester.tap(find.bySemanticsLabel("Go back").last);
      await tester.pump();
      expect(calls.interactions.last.type, UserInteractionType.dismiss);
      nested.add(issuance(SessionStatus.dismissed));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 2, 3))),
        findsOneWidget,
      );
      expect(find.text("Open again"), findsOneWidget);
    });

    testWidgets("closing once adding has started asks first", (tester) async {
      final (calls, nested) = await openWebsite(tester);
      comeBack(tester);
      nested.add(issuance(SessionStatus.requestPermission));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key("disclosure_choice_sheet")),
          matching: find.byType(IrmaCloseButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Stop adding ID card?"), findsOneWidget);
      await tester.tap(find.byKey(const Key("sheet_stop_keep")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("disclosure_choice_sheet")), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key("disclosure_choice_sheet")),
          matching: find.byType(IrmaCloseButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_stop_confirm")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("disclosure_choice_sheet")), findsNothing);
      // The issuance in the sheet is ended with it.
      expect(
        calls.interactions.where(
          (e) =>
              e.sessionId == nestedId && e.type == UserInteractionType.dismiss,
        ),
        isNotEmpty,
      );
    });

    testWidgets("tablet: the same steps in the dialog, and nothing flies", (
      tester,
    ) async {
      final nested = StreamController<SessionState>();
      addTearDown(nested.close);
      await _pump(
        tester,
        size: const Size(1180, 820),
        session: _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: const [],
            obtainableOptions: [_descriptor("idcard", "ID card")],
          ),
        ]),
        nested: {nestedId: nested.stream},
      );
      await tester.tap(find.byKey(const Key("share_spot_0")));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 1, 3))),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await tester.pumpAndSettle();
      comeBack(tester);
      nested.add(issuance(SessionStatus.requestPermission));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 3, 3))),
        findsOneWidget,
      );
      nested.add(issuance(SessionStatus.success));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key("sheet_back_to_request")));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key("sheet_flight_card")), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("disclosure_choice_sheet")), findsNothing);
    });

    testWidgets("choosing does not ask: the choice list just closes", (
      tester,
    ) async {
      await _pump(tester, session: _session([_passportOrIdCard()]));
      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key("disclosure_choice_sheet")),
          matching: find.byType(IrmaCloseButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("sheet_stop_dialog")), findsNothing);
      expect(find.byKey(const Key("disclosure_choice_sheet")), findsNothing);
    });
  });

  group("adding an e-mail address in the sheet", () {
    const nestedId = 2;
    final email = CredentialDescriptor(
      credentialId: "pbdf.sidn-pbdf.email",
      name: "Email address",
      issuer: _party("Yivi"),
      category: null,
      attributes: [],
      issueURL: "https://email-issuer.example/issue",
    );
    final request = _session([
      DisclosurePickOne(
        optional: false,
        ownedOptions: [_bundle(_instance("passport", "Passport", "Jansen"))],
        obtainableOptions: [email],
      ),
    ]);

    /// The sheet on the e-mail step, with the issuer faked.
    Future<(_Calls, _FakeEmailApi, StreamController<SessionState>)> open(
      WidgetTester tester,
    ) async {
      final api = _FakeEmailApi();
      final nested = StreamController<SessionState>();
      // Not awaited: without a listener (no issuance started) close() never
      // completes.
      addTearDown(() {
        nested.close();
      });
      final calls = await _pump(
        tester,
        session: request,
        nested: {nestedId: nested.stream},
        overrides: [emailIssuerApiProvider.overrideWithValue(api)],
      );
      // The request waits, as far as the repository knows; and the next
      // session id is not the request's.
      await tester.runAsync(() async {
        calls.repo.dispatch(SessionStateEvent(sessionState: request));
        await Future<void>.delayed(Duration.zero);
      });
      expect(calls.repo.isActiveSession(_sessionId), isTrue);
      calls.repo.allocateSessionId();
      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_add_pbdf.sidn-pbdf.email")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await _pumpFor(tester);
      return (calls, api, nested);
    }

    testWidgets("address, code, then the issuance: all in the sheet", (
      tester,
    ) async {
      final (calls, api, nested) = await open(tester);
      // Step 2: the address, in the sheet (no e-mail screen is pushed).
      expect(find.text("Add email address"), findsOneWidget);
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 2, 4))),
        findsOneWidget,
      );
      expect(calls.obtained, isEmpty);

      await tester.enterText(
        find.byKey(const Key("email_input_field")),
        "sanne@devries.example",
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key("contact_sheet_send")));
      // The code's cursor blinks, so it never settles: pump a while.
      await _pumpFor(tester);
      expect(api.sent, ["sanne@devries.example"]);
      // The same page: the address folds into "Code sent to", the code
      // boxes come under it.
      expect(find.text("Add email address"), findsOneWidget);
      expect(find.text("Code sent to"), findsOneWidget);
      // The code is a step of its own.
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 3, 4))),
        findsOneWidget,
      );
      expect(find.text("sanne@devries.example"), findsOneWidget);
      expect(find.byKey(const Key("email_input_field")), findsNothing);

      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        "ABC123",
      );
      await _pumpFor(tester);
      expect(api.verified, ["ABC123"]);

      // The checked code starts the issuance, which shows in the sheet.
      nested.add(
        SessionState(
          id: nestedId,
          protocol: "irma",
          type: SessionType.issuance,
          status: SessionStatus.requestPermission,
          requestor: _party("Yivi"),
          offeredCredentials: [
            testCredential(
              type: "pbdf.sidn-pbdf.email",
              hash: "new-email",
              name: "Email address",
            ),
          ],
        ),
      );
      await _pumpFor(tester);
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 4, 4))),
        findsOneWidget,
      );
      expect(find.byKey(const Key("sheet_issuance")), findsOneWidget);
    });

    testWidgets("one button; closing asks first", (tester) async {
      await open(tester);
      final sheet = find.byKey(const Key("disclosure_choice_sheet"));
      expect(
        find.descendant(of: sheet, matching: find.text("Cancel")),
        findsNothing,
      );
      // The field has focus at once: the keyboard is up.
      expect(tester.testTextInput.isVisible, isTrue);
      // A focused field's cursor blinks, so the pages never settle.
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key("disclosure_choice_sheet")),
          matching: find.byType(IrmaCloseButton),
        ),
      );
      await _pumpFor(tester);
      expect(find.text("Stop adding email address?"), findsOneWidget);
      await tester.tap(find.byKey(const Key("sheet_stop_confirm")));
      await _pumpFor(tester);
      // The sheet closes; nothing added.
      expect(sheet, findsNothing);
    });

    Future<void> sendCode(WidgetTester tester) async {
      await tester.enterText(
        find.byKey(const Key("email_input_field")),
        "sanne@devries.example",
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key("contact_sheet_send")));
      await _pumpFor(tester);
    }

    testWidgets("Change: back on the address, filled in", (tester) async {
      await open(tester);
      await sendCode(tester);
      await tester.tap(find.byKey(const Key("contact_sheet_change")));
      await _pumpFor(tester);
      expect(find.byKey(const Key("contact_sheet_code")), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key("email_input_field")))
            .controller!
            .text,
        "sanne@devries.example",
      );
    });

    testWidgets("a code that can't be checked: said under the boxes", (
      tester,
    ) async {
      final (_, api, _) = await open(tester);
      api.failCodes = true;
      await sendCode(tester);
      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        "WRONG1",
      );
      await _pumpFor(tester);
      expect(find.byKey(const Key("contact_sheet_error")), findsOneWidget);
      expect(
        find.text("We could not check the code. Try again."),
        findsOneWidget,
      );
      // Typing again clears it.
      await tester.enterText(
        find.byKey(const Key("email_verification_code_input_field")),
        "A",
      );
      await _pumpFor(tester);
      expect(find.byKey(const Key("contact_sheet_error")), findsNothing);
      expect(find.text("Not there? Check your spam."), findsOneWidget);
    });

    testWidgets("back from the e-mail step returns to the details", (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel("Go back").last);
      await _pumpFor(tester);
      expect(find.byKey(const Key("add_data_details_issuer")), findsOneWidget);
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 1, 4))),
        findsOneWidget,
      );
    });
  });

  group("adding a document in the sheet", () {
    const nestedId = 2;
    final passport = CredentialDescriptor(
      credentialId: "pbdf.pbdf.passport",
      name: "Passport",
      issuer: _party("Yivi"),
      category: null,
      attributes: [],
      issueURL: "https://passport-issuer.example/issue",
    );
    final request = _session([
      DisclosurePickOne(
        optional: false,
        ownedOptions: [_bundle(_instance("idcard", "ID card", "Jansen"))],
        obtainableOptions: [passport],
      ),
    ]);
    Finder inSheet(Finder f) => find.descendant(
      of: find.byKey(const Key("disclosure_choice_sheet")),
      matching: f,
    );

    /// The sheet on the passport's instruction (its picture's sweep never
    /// settles).
    Future<(_Calls, StreamController<SessionState>)> open(
      WidgetTester tester,
    ) async {
      final nested = StreamController<SessionState>();
      addTearDown(() {
        nested.close();
      });
      final calls = await _pump(
        tester,
        session: request,
        nested: {nestedId: nested.stream},
      );
      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_add_pbdf.pbdf.passport")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await _pumpFor(tester);
      return (calls, nested);
    }

    testWidgets("the instruction and the manual entry open in the sheet", (
      tester,
    ) async {
      final (calls, _) = await open(tester);
      expect(
        inSheet(find.byKey(const Key("document_instruction_picture"))),
        findsOneWidget,
      );
      expect(calls.obtained, isEmpty);
      // A document takes five steps; how to hold it is the second.
      expect(
        inSheet(find.byKey(const ValueKey(("issue_sheet_progress", 2, 5)))),
        findsOneWidget,
      );
      // The sheet waits for the issuance the chip read starts.
      expect(
        ProviderScope.containerOf(
          tester.element(find.byType(ChangeChoiceSheet)),
        ).read(nestedIssuanceHostProvider)?.underlyingSessionId,
        _sessionId,
      );

      // No camera here: Start goes to typing it in.
      await tester.tap(inSheet(find.byKey(DocumentFlowButton.primaryKey)));
      await _pumpFor(tester);
      expect(
        inSheet(find.byType(PassportMrzManualEntryScreen)),
        findsOneWidget,
      );
      expect(
        inSheet(find.byKey(const ValueKey(("issue_sheet_progress", 3, 5)))),
        findsOneWidget,
      );

      // Back steps back in the flow, then to the details.
      await tester.tap(find.bySemanticsLabel("Go back").last);
      await _pumpFor(tester);
      expect(
        inSheet(find.byKey(const Key("document_instruction_picture"))),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel("Go back").last);
      await _pumpFor(tester);
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 1, 5))),
        findsOneWidget,
      );
      expect(find.byType(DocumentInstructionScreen), findsNothing);
    });

    testWidgets("the sheet's own bar: no Cancel, closing asks", (tester) async {
      await open(tester);
      // The screen's own bar and Cancel are gone; the sheet's bar has the
      // title, back and close, also for screen readers.
      expect(inSheet(find.byType(IrmaAppBar)), findsNothing);
      expect(
        inSheet(find.byKey(DocumentFlowButton.secondaryKey)),
        findsNothing,
      );
      expect(find.bySemanticsLabel("Scan passport"), findsOneWidget);
      expect(find.bySemanticsLabel("Go back"), findsWidgets);

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key("disclosure_choice_sheet")),
          matching: find.byType(IrmaCloseButton),
        ),
      );
      await _pumpFor(tester);
      expect(find.text("Stop adding passport?"), findsOneWidget);
      await tester.tap(find.byKey(const Key("sheet_stop_confirm")));
      await _pumpFor(tester);
      expect(find.byKey(const Key("disclosure_choice_sheet")), findsNothing);
    });

    testWidgets(
      "the chip read's issuance is the last step; back, the details",
      (tester) async {
        final (_, nested) = await open(tester);
        // What the chip screen's handlePointer does once the issuer is called.
        ProviderScope.containerOf(
          tester.element(find.byType(ChangeChoiceSheet)),
        ).read(nestedIssuanceHostProvider)!.attach(nestedId);
        nested.add(
          SessionState(
            id: nestedId,
            protocol: "irma",
            type: SessionType.issuance,
            status: SessionStatus.requestPermission,
            requestor: _party("Yivi"),
            offeredCredentials: [
              testCredential(
                type: "pbdf.pbdf.passport",
                hash: "new-passport",
                name: "Passport",
              ),
            ],
          ),
        );
        await _pumpFor(tester);
        expect(
          find.byKey(const ValueKey(("issue_sheet_progress", 5, 5))),
          findsOneWidget,
        );
        expect(find.byKey(const Key("sheet_issuance")), findsOneWidget);

        // Back there: on the details, the document to be read again.
        await tester.tap(find.bySemanticsLabel("Go back").last);
        await tester.pump();
        nested.add(
          SessionState(
            id: nestedId,
            protocol: "irma",
            type: SessionType.issuance,
            status: SessionStatus.dismissed,
            requestor: _party("Yivi"),
          ),
        );
        await _pumpFor(tester);
        expect(
          find.byKey(const ValueKey(("issue_sheet_progress", 1, 5))),
          findsOneWidget,
        );
        expect(find.byType(DocumentInstructionScreen), findsNothing);
      },
    );
  });

  group("who you share with", () {
    TrustedParty party({
      bool verified = false,
      String? level,
      String? source,
    }) => TrustedParty(
      id: "shop",
      name: "Webshop Noord",
      url: null,
      parent: null,
      verified: verified,
      trustLevel: level,
      trustSource: source,
    );
    List<DisclosurePickOne> email() => [
      DisclosurePickOne(
        optional: false,
        ownedOptions: [_bundle(_instance("email", "Email", "s@werk.example"))],
      ),
    ];
    final wash = find.byKey(const Key("share_trust_wash"));

    testWidgets("registered: calm, and Share names who gets it", (
      tester,
    ) async {
      await _pump(tester, session: _session(email()));
      expect(find.text("Registered with Yivi"), findsOneWidget);
      expect(wash, findsNothing);
      expect(find.text("Share with Webshop Noord"), findsOneWidget);
    });

    testWidgets("medium: just as calm, verified in the EU", (tester) async {
      await _pump(
        tester,
        session: _session(
          email(),
          requestor: party(level: "medium", source: "eu_trusted_list"),
        ),
      );
      expect(find.text("Verified in the EU"), findsOneWidget);
      expect(wash, findsNothing);
      expect(find.text("Share with Webshop Noord"), findsOneWidget);
    });

    testWidgets("unknown: the red page, Share anyway, and it asks first", (
      tester,
    ) async {
      final calls = await _pump(
        tester,
        session: _session(email(), requestor: party()),
      );
      // A red ! on the logo and a red pill, no banner.
      expect(find.text("Not checked"), findsOneWidget);
      expect(find.byType(RequestorTrustBadge), findsOneWidget);
      expect(find.byKey(const Key("share_trust_banner")), findsNothing);
      expect(wash, findsOneWidget);
      expect(
        find.text("Only share if you trust Webshop Noord"),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _share, matching: find.text("Share anyway")),
        findsOneWidget,
      );

      // "Don't share" is the safe, big answer: nothing is sent.
      await tester.tap(_share);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("share_anyway_dialog")), findsOneWidget);
      await tester.tap(find.byKey(const Key("share_anyway_cancel")));
      await tester.pumpAndSettle();
      expect(calls.shared, isEmpty);

      await tester.tap(_share);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("share_anyway_confirm")));
      await tester.pumpAndSettle();
      expect(calls.shared, hasLength(1));
    });

    testWidgets("not evaluated: no colour, no claim, nothing to tap", (
      tester,
    ) async {
      await _pump(
        tester,
        session: _session(email(), requestor: party(level: "")),
      );
      expect(find.byKey(const Key("session_requestor_trust")), findsNothing);
      await tester.tap(find.byKey(const Key("session_requestor_header")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("requestor_trust_sheet")), findsNothing);
    });

    testWidgets("the logo flies from the card into the trust sheet", (
      tester,
    ) async {
      await _pump(tester, session: _session(email()));
      final logo = find.byType(RequestorLogo);
      final from = tester.getRect(logo);
      expect(from.width, 64);

      await tester.tap(find.byKey(const Key("session_requestor_header")));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      // Mid-flight: one logo on its way, between the two sizes.
      // (The copy in flight is the hero's child: measure the scaled box.)
      final sizes = [
        for (final e in find.byType(FittedBox).evaluate())
          tester.getRect(find.byWidget(e.widget)).width,
      ];
      expect(sizes.any((w) => w > 64 && w < 84), isTrue);

      await tester.pumpAndSettle();
      final inSheet = find.descendant(
        of: find.byKey(const Key("requestor_trust_sheet")),
        matching: logo,
      );
      expect(tester.getRect(inSheet).width, 84);
    });

    testWidgets("the party opens what registered means", (tester) async {
      await _pump(tester, session: _session(email()));
      await tester.tap(find.byKey(const Key("session_requestor_header")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("requestor_trust_sheet")), findsOneWidget);
      expect(find.byKey(const Key("trust_sheet_head")), findsOneWidget);
      expect(find.text("Yivi checked who they are"), findsOneWidget);
      expect(find.text("They are listed on the Yivi Portal"), findsOneWidget);
    });

    testWidgets("unknown: the card explains, and Don't share closes", (
      tester,
    ) async {
      final calls = await _pump(
        tester,
        session: _session(email(), requestor: party()),
      );
      await tester.tap(find.byKey(const Key("session_requestor_header")));
      await tester.pumpAndSettle();
      expect(find.text("Unknown to Yivi"), findsOneWidget);
      expect(find.text("Nobody checked who they are"), findsOneWidget);
      await tester.tap(find.byKey(const Key("trust_sheet_dont_share")));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("requestor_trust_sheet")), findsNothing);
      expect(calls.closed, 1);
      expect(calls.shared, isEmpty);
    });

    testWidgets("medium: the sheet says who vouches, without a red cross", (
      tester,
    ) async {
      await _pump(
        tester,
        session: _session(
          email(),
          requestor: party(level: "medium", source: "eu_trusted_list"),
        ),
      );
      await tester.tap(find.byKey(const Key("session_requestor_header")));
      await tester.pumpAndSettle();
      expect(find.text("Verified by an EU trust service"), findsOneWidget);
      expect(
        find.text("They are not registered with Yivi itself"),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(find.byKey(const Key("trust_sheet_eu_list")), findsOneWidget);
    });

    testWidgets("scrolled past the card: who asks in the bar", (tester) async {
      await _pump(
        tester,
        session: _session([
          for (var n = 0; n < 4; n++)
            DisclosurePickOne(
              optional: false,
              ownedOptions: [
                _bundle(_instance("email$n", "Email", "s$n@werk.example")),
              ],
            ),
        ], requestor: party()),
      );
      final bar = find.byKey(const Key("requestor_compact_bar"));
      expect(bar, findsNothing);
      await tester.drag(
        find.byKey(const Key("share_scroll_view")),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(bar, findsOneWidget);
      // Nobody vouches: a red ! on its logo.
      expect(
        find.descendant(of: bar, matching: find.byType(RequestorTrustBadge)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: bar,
          matching: find.text("is asking for your data"),
        ),
        findsOneWidget,
      );
    });

    testWidgets("a short page: the footnote and details at its bottom", (
      tester,
    ) async {
      await _pump(tester, session: _session(email()));
      final link = tester.getRect(
        find.byKey(const Key("share_technical_details")),
      );
      final button = tester.getRect(_share);
      // Just above the bar, not right under the card.
      expect(button.top - link.bottom, lessThan(140));
    });

    testWidgets("technical details: last on the page, in their own sheet", (
      tester,
    ) async {
      await _pump(tester, session: _session(email()));
      final link = find.byKey(const Key("share_technical_details"));
      await tester.scrollUntilVisible(
        link,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("technical_details_sheet")), findsOneWidget);
      expect(find.text("IRMA"), findsOneWidget);
      expect(find.text("Idemix · from RvIG"), findsOneWidget);
      // Nothing personal in it.
      expect(
        find.descendant(
          of: find.byKey(const Key("technical_details_sheet")),
          matching: find.text("s@werk.example"),
        ),
        findsNothing,
      );
    });
  });

  group("landscape", () {
    // An iPhone 17 Pro on its side: the notch side's safe area left and
    // right, the home indicator below.
    const phone = Size(874, 402);
    const insets = FakeViewPadding(left: 62, right: 62, bottom: 21);
    Future<_Calls> pumpSideways(WidgetTester tester, SessionState session) =>
        _pump(tester, session: session, size: phone, padding: insets);
    final panel = find.byKey(const Key("share_panel"));
    final card = find.byKey(const Key("session_requestor_header"));

    testWidgets("who asks once, in the panel, with the button", (tester) async {
      await pumpSideways(tester, _session([_passportOrIdCard()]));
      expect(card, findsOneWidget);
      expect(find.descendant(of: panel, matching: card), findsOneWidget);
      expect(find.descendant(of: panel, matching: _share), findsOneWidget);
      expect(find.byType(IrmaBottomBarBase), findsNothing);
      expect(
        find.text(
          "Next to this is exactly what they get. Nothing is sent until you "
          "press the share button.",
        ),
        findsOneWidget,
      );
      // No pill in the bar, also once scrolled.
      await tester.drag(
        find.byKey(const Key("share_scroll_view")),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RequestorCompactBar), findsNothing);
      // Close in the corner, 16 from the edge, beside the column.
      expect(tester.getRect(find.byType(IrmaCloseButton)).right, 874 - 16);
    });

    for (final (name, size, padding) in [
      (
        "unfolded phone",
        const Size(951, 669),
        const FakeViewPadding(right: 84, bottom: 34),
      ),
      ("tablet", const Size(1180, 820), const FakeViewPadding(bottom: 20)),
    ]) {
      testWidgets("$name held sideways: the phone's panel, with the button; "
          "only the right side scrolls", (tester) async {
        await _pump(
          tester,
          session: _session([_passportOrIdCard()]),
          size: size,
          padding: padding,
        );
        expect(find.byType(SessionColumns), findsNothing);
        expect(find.descendant(of: panel, matching: card), findsOneWidget);
        expect(find.descendant(of: panel, matching: _share), findsOneWidget);
        expect(find.byType(IrmaBottomBarBase), findsNothing);
        // Clear of the side panel.
        expect(
          tester.getRect(find.byType(IrmaCloseButton)).right,
          lessThanOrEqualTo(size.width - padding.right),
        );

        final share = tester.getRect(_share);
        await tester.drag(
          find.byKey(const Key("share_scroll_view")),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(_share), share);
      });
    }

    testWidgets("the panel's card is level with the first card", (
      tester,
    ) async {
      await pumpSideways(tester, _session([_passportOrIdCard()]));
      expect(
        tester.getRect(card).top,
        tester.getRect(find.byKey(const Key("share_slot_0"))).top,
      );
    });

    testWidgets("level with an empty spot", (tester) async {
      await pumpSideways(
        tester,
        _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: const [],
            obtainableOptions: [_descriptor("idcard", "ID card")],
          ),
        ]),
      );
      final tile = find.descendant(
        of: find.byKey(const Key("share_spot_0")),
        matching: find.byType(CardTile),
      );
      expect(tester.getRect(card).top, tester.getRect(tile).top);
    });

    testWidgets("level with the message to sign", (tester) async {
      await pumpSideways(
        tester,
        _session(
          [_passportOrIdCard()],
          type: SessionType.signature,
          message: "I agree.",
        ),
      );
      // The message's card: 14 above its label.
      expect(
        tester.getRect(card).top,
        tester.getRect(find.text("You sign this message")).top - 14,
      );
    });

    testWidgets("sheets: between the safe areas, two columns, the button "
        "at the right", (tester) async {
      await pumpSideways(tester, _session([_passportOrIdCard()]));
      // Kies een kaartje: the two cards side by side.
      await tester.tap(find.byKey(const Key("share_change_0")));
      await tester.pumpAndSettle();
      final sheet = tester.getRect(find.byKey(const Key("glass_sheet")));
      expect(sheet.left, 62);
      expect(sheet.right, 874 - 62);
      final passport = tester.getRect(
        find.byKey(const Key("sheet_owned_hash-passport-Jansen")),
      );
      final idcard = tester.getRect(
        find.byKey(const Key("sheet_owned_hash-idcard-de Vries")),
      );
      expect(passport.top, idcard.top);
      expect(idcard.left, greaterThan(passport.right));
    });

    testWidgets("adding: the card and the button left, what you get right; "
        "the progress next to the title, who it is for under it", (
      tester,
    ) async {
      await pumpSideways(
        tester,
        _session([
          DisclosurePickOne(
            optional: false,
            ownedOptions: const [],
            obtainableOptions: [_descriptor("idcard", "ID card")],
          ),
        ]),
      );
      await tester.tap(find.byKey(const Key("share_spot_0")));
      await tester.pumpAndSettle();
      // The button at the bottom of the left column, as wide as it; no bar.
      final go = tester.getRect(find.byKey(const Key("sheet_go_button")));
      expect(go.left, 62 + 20);
      expect(go.width, 280);
      // As low as the buttons of a full screen.
      expect(go.bottom, inInclusiveRange(402 - 40, 402 - 16));
      expect(find.byType(SheetBottomBar), findsNothing);
      final youGet = tester.getRect(find.byKey(const Key("add_data_you_get")));
      expect(youGet.left, greaterThan(go.right));
      // One bar: the title, the progress with "1 of 3" after it, and under
      // the title who the card is for.
      final title = tester.getRect(find.byKey(const Key("glass_sheet_title")));
      final count = tester.getRect(
        find.byKey(const Key("issue_sheet_progress_text")),
      );
      // The test's card goes via a website: three steps.
      expect(find.text("1 of 3"), findsOneWidget);
      expect(count.center.dy, closeTo(title.bottom, 12));
      final forWho = tester.getRect(
        find.byKey(const Key("issue_sheet_for_requestor")),
      );
      expect(forWho.top, greaterThanOrEqualTo(title.bottom));
      expect(forWho.left, title.left);
    });

    testWidgets("who is this, and the technical details, in two columns", (
      tester,
    ) async {
      await pumpSideways(tester, _session([_passportOrIdCard()]));
      await tester.tap(find.byKey(const Key("session_requestor_header")));
      await tester.pumpAndSettle();
      final head = tester.getRect(find.byKey(const Key("trust_sheet_head")));
      final fact = tester.getRect(find.text("Yivi checked who they are"));
      expect(fact.left, greaterThan(head.right));
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key("requestor_trust_sheet")),
          matching: find.byType(IrmaCloseButton),
        ),
      );
      await tester.pumpAndSettle();

      final link = find.byKey(const Key("share_technical_details"));
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      await tester.tap(link);
      await tester.pumpAndSettle();
      final who = tester.getRect(find.text("WHO ASKS"));
      final how = tester.getRect(find.text("HOW YOU SHARE"));
      expect(who.top, how.top);
      expect(how.left, greaterThan(who.right));
    });

    testWidgets("nobody vouches: the red ! and Not checked in the panel", (
      tester,
    ) async {
      await pumpSideways(
        tester,
        _session(
          [_passportOrIdCard()],
          requestor: TrustedParty(
            id: "x",
            name: "deals.example",
            url: null,
            parent: null,
            verified: false,
          ),
        ),
      );
      expect(
        find.descendant(of: panel, matching: find.text("Not checked")),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.byType(RequestorTrustBadge)),
        findsOneWidget,
      );
      expect(find.text("Share anyway"), findsOneWidget);
    });
  });
}

/// Pumps frames for [duration], for a page that never settles (a blinking
/// cursor).
Future<void> _pumpFor(
  WidgetTester tester, [
  Duration duration = const Duration(seconds: 1),
]) async {
  for (
    var t = Duration.zero;
    t < duration;
    t += const Duration(milliseconds: 50)
  ) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// The e-mail issuer, faked: sending always works; any code gives a session.
class _FakeEmailApi implements EmailIssuerApi {
  final sent = <String>[];
  final verified = <String>[];

  /// Every code fails to verify.
  var failCodes = false;

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
    verified.add(verificationCode);
    if (failCodes) throw Exception("could not verify");
    return SessionPointer(
      u: "https://irma.example/session/abc",
      irmaqr: "issuing",
      protocol: Protocol.irma,
      continueOnSecondDevice: true,
    );
  }
}
