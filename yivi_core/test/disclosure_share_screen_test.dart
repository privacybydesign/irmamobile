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

    await tester.tap(find.text("de Vries"));
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
    await tester.tap(find.text("ID card"));
    await tester.pumpAndSettle();

    expect(find.text("details"), findsOneWidget);
    expect(calls.obtained.single, contains('"credential_id":"idcard"'));
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
      await tester.tap(find.text("de Vries"));
      await tester.pumpAndSettle();

      expect(find.text("de Vries"), findsOneWidget);
      expect(find.text("Share"), findsOneWidget);

      await tester.tap(find.byKey(const Key("share_remove_0")));
      await tester.pumpAndSettle();
      expect(find.text("de Vries"), findsNothing);

      await tester.tap(_share);
      expect(_hashes(calls.shared.single), [<String>[]]);
    });

    testWidgets("obtained while the sheet is open, it is included", (
      tester,
    ) async {
      final sessions = StreamController<SessionState>();
      addTearDown(sessions.close);
      sessions.add(
        _session([
          DisclosurePickOne(
            optional: true,
            ownedOptions: [
              _bundle(_instance("passport", "Passport", "Jansen")),
            ],
            obtainableOptions: [_descriptor("idcard", "ID card")],
          ),
        ]),
      );
      await _pump(tester, sessions: sessions.stream);

      await tester.tap(find.byKey(const Key("share_add_optional_0")));
      await tester.pumpAndSettle();
      sessions.add(
        _session([
          DisclosurePickOne(
            optional: true,
            ownedOptions: [
              _bundle(_instance("passport", "Passport", "Jansen")),
              _bundle(_instance("idcard", "ID card", "de Vries")),
            ],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      final sheetTitle = find.text("What do you want to share?");
      Navigator.of(tester.element(sheetTitle)).pop();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key("share_slot_0")), findsOneWidget);
      expect(find.text("de Vries"), findsOneWidget);
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

      await tester.tap(find.byKey(const Key("shared_card_fix")));
      await tester.pumpAndSettle();
      expect(calls.obtained.single, contains('"credential_id":"address"'));
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

  testWidgets("tablet: two columns, the title stays in the bar", (
    tester,
  ) async {
    await _pump(
      tester,
      session: _session([_passportOrIdCard()]),
      size: const Size(1280, 900),
    );
    expect(find.byType(SessionColumns), findsOneWidget);
    expect(find.byKey(const Key("irma_app_bar_title")), findsNothing);
    // Who asks on the left, what is shared on the right.
    final header = tester.getRect(
      find.byKey(const Key("session_requestor_header")),
    );
    expect(
      tester.getRect(find.byKey(const Key("share_slot_0"))).left,
      greaterThan(header.right),
    );
  });
}
