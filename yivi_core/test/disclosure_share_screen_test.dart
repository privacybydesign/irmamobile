import "dart:async";

import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/schemaless/session_user_interaction.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/session/widgets/change_choice_sheet.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/session_columns.dart";
import "package:yivi_core/src/theme/theme.dart";

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

CredentialDescriptor _descriptor(String id, String name) =>
    CredentialDescriptor(
      credentialId: id,
      name: name,
      issuer: _party("Issuer"),
      category: null,
      attributes: const [],
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
}) => SessionState(
  id: _sessionId,
  protocol: "irma",
  type: type,
  status: SessionStatus.requestPermission,
  requestor: _party("Webshop Noord"),
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
}

class _Screen extends ConsumerWidget {
  final _Calls calls;
  final bool banner;

  const _Screen(this.calls, {this.banner = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider(_sessionId)).value;
    if (session == null) return const SizedBox();
    return DisclosureShareScreen(
      session: session,
      showAddedBanner: banner,
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
  Size size = const Size(390, 844),
  bool banner = false,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final calls = _Calls();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: "/",
        builder: (_, _) => _Screen(calls, banner: banner),
      ),
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
        // Where "Go to …" sends the user, recorded instead of opened.
        issuerOpenerProvider.overrideWithValue(
          (context, d, ref) async => calls.obtained.add(d.credentialId),
        ),
      ],
      child: IrmaTheme(
        builder: (_) => MaterialApp.router(
          routerConfig: router,
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

    expect(find.text("Do you want to share this data?"), findsOneWidget);
    expect(find.text("Webshop Noord"), findsOneWidget);
    expect(find.text("YOU SHARE"), findsOneWidget);
    expect(find.text("s@werk.example"), findsOneWidget);
    // Only one option: nothing to change.
    expect(find.byKey(const Key("share_change_0")), findsNothing);
    expect(find.byKey(const Key("share_reason")), findsNothing);

    // The button is the consent: no dialog, the choices are sent at once.
    await tester.tap(find.descendant(of: _share, matching: find.text("Share")));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(_hashes(calls.shared.single), [
      ["hash-email-s@werk.example"],
    ]);
  });

  testWidgets("Change opens the sheet; a tap picks and closes", (tester) async {
    final calls = await _pump(tester, session: _session([_passportOrIdCard()]));

    expect(find.text("Jansen"), findsOneWidget);
    await tester.tap(find.byKey(const Key("share_change_0")));
    await tester.pumpAndSettle();
    expect(find.text("What do you want to share?"), findsOneWidget);

    await tester.tap(find.byKey(const Key("sheet_owned_hash-idcard-de Vries")));
    await tester.pumpAndSettle();
    expect(find.text("What do you want to share?"), findsNothing);
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
    expect(find.text("Issuer · on issuer.example"), findsOneWidget);

    // First where the user goes, then there.
    await tester.tap(find.byKey(const Key("sheet_add_idcard")));
    await tester.pumpAndSettle();
    expect(find.text("Add ID card"), findsOneWidget);
    expect(find.text("Back here, already selected"), findsOneWidget);
    expect(calls.obtained, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key("sheet_go_button")),
        matching: find.text("Go to issuer.example"),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("disclosure_choice_sheet")), findsNothing);
    expect(calls.obtained, ["idcard"]);
  });

  group("optional data", () {
    testWidgets("starts left out; Add includes it, × leaves it out again", (
      tester,
    ) async {
      final calls = await _pump(
        tester,
        session: _session([_passportOrIdCard(optional: true)]),
      );

      expect(find.text("Jansen"), findsNothing);
      expect(find.text("Passport or ID card"), findsOneWidget);
      expect(find.text("Share without data"), findsOneWidget);
      expect(
        find.text("Webshop Noord asks for nothing you must share."),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key("share_add_optional_0")));
      await tester.pumpAndSettle();
      expect(find.text("Add optional data"), findsOneWidget);
      await tester.tap(
        find.byKey(const Key("sheet_owned_hash-idcard-de Vries")),
      );
      await tester.pumpAndSettle();

      expect(find.text("de Vries"), findsOneWidget);
      expect(find.text("Share"), findsOneWidget);

      await tester.tap(find.byKey(const Key("share_remove_0")));
      await tester.pumpAndSettle();
      expect(find.text("de Vries"), findsNothing);

      await tester.tap(_share);
      expect(_hashes(calls.shared.single), [<String>[]]);
    });

    testWidgets("a card added for it is included once it arrives", (
      tester,
    ) async {
      final sessions = StreamController<SessionState>();
      addTearDown(sessions.close);
      DisclosurePickOne optional(List<SelectableCredentialInstance> owned) =>
          DisclosurePickOne(
            optional: true,
            ownedOptions: [for (final i in owned) _bundle(i)],
            obtainableOptions: [_descriptor("idcard", "ID card")],
          );
      final passport = _instance("passport", "Passport", "Jansen");
      sessions.add(
        _session([
          optional([passport]),
        ]),
      );
      final calls = await _pump(tester, sessions: sessions.stream);

      await tester.tap(find.byKey(const Key("share_add_optional_0")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_add_idcard")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await tester.pumpAndSettle();
      expect(calls.obtained, ["idcard"]);
      // Not included before the card is there.
      expect(find.byKey(const Key("share_slot_0")), findsNothing);

      sessions.add(
        _session([
          optional([passport, _instance("idcard", "ID card", "de Vries")]),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key("share_slot_0")), findsOneWidget);
      expect(find.text("de Vries"), findsOneWidget);
    });

    testWidgets("leaving the sheet without adding changes nothing", (
      tester,
    ) async {
      await _pump(
        tester,
        session: _session([_passportOrIdCard(optional: true)]),
      );

      await tester.tap(find.byKey(const Key("share_add_optional_0")));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel("Close").last);
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
      expect(find.text("Replace the revoked card to share."), findsOneWidget);
      await tester.tap(_share);
      expect(calls.shared, isEmpty);

      // The fix opens the sheet straight on adding a new one.
      await tester.tap(find.byKey(const Key("shared_card_fix")));
      await tester.pumpAndSettle();
      expect(find.text("Add address"), findsOneWidget);
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

    expect(find.text("Do you want to sign this message?"), findsOneWidget);
    expect(find.text("You sign this message"), findsOneWidget);
    expect(find.text("WITH YOUR SIGNATURE"), findsOneWidget);
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
      find.text("Do you want to share this data and add a card?"),
      findsOneWidget,
    );
    expect(find.text("YOU RECEIVE"), findsOneWidget);
    expect(find.text("Share and add card"), findsOneWidget);
  });

  testWidgets("after adding missing data: Everything is added", (tester) async {
    await _pump(tester, session: _session([_passportOrIdCard()]), banner: true);
    expect(
      find.text("Everything is added. Check what you share."),
      findsOneWidget,
    );
  });

  testWidgets("tablet: the question, who asks and the footnote left, what "
      "is shared right", (tester) async {
    await _pump(
      tester,
      session: _session([_passportOrIdCard()]),
      size: const Size(1280, 900),
    );
    expect(find.byType(SessionColumns), findsOneWidget);
    final slot = tester.getRect(find.byKey(const Key("share_slot_0")));
    for (final left in [
      "large_title",
      "session_requestor_header",
      "share_footnote",
    ]) {
      expect(
        tester.getRect(find.byKey(Key(left))).right,
        lessThan(slot.left),
        reason: left,
      );
    }
  });

  group("the Change sheet", () {
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

      expect(find.text("Which email address?"), findsOneWidget);
      expect(find.text("IN YOUR APP"), findsOneWidget);
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
      final from = tester.getRect(picked).top;

      await tester.tap(picked);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      // Mid-flight: the one card showing the new choice is on its way up.
      final flying = tester.getRect(find.text("de Vries")).top;

      await tester.pumpAndSettle();
      final to = tester.getRect(find.text("de Vries")).top;
      expect(flying, lessThan(from));
      expect(flying, greaterThan(to));
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

      expect(find.text("What do you want to share?"), findsOneWidget);
    });
  });
}
