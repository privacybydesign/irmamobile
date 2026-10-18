import "dart:async";

import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart" show DocumentType;
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/protocol.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/schemaless/session_user_interaction.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/providers/email_issuance_provider.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/nested_issuance_host_provider.dart";
import "package:yivi_core/src/providers/nfc_availability_provider.dart";
import "package:yivi_core/src/providers/pane_selection_provider.dart";
import "package:yivi_core/src/providers/schemaless_credential_store_provider.dart";
import "package:yivi_core/src/providers/schemaless_credentials_list_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/add_data/add_data_sheet.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_instruction_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issue_flow.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";

import "helpers/credential_factory.dart";
import "support/onboarding_v2_harness.dart";
import "support/pump_translated.dart";

TrustedParty _party(String name) =>
    TrustedParty(id: name, name: name, url: null, parent: null, verified: true);

CredentialStoreItem _item(
  String credentialId,
  String name, {
  String? issueURL,
  String issuer = "Issuer",
}) => CredentialStoreItem(
  credential: CredentialDescriptor(
    credentialId: credentialId,
    name: name,
    issuer: _party(issuer),
    category: "Personal",
    attributes: const [],
    issueURL: issueURL,
  ),
  faq: Faq(
    intro: "intro",
    purpose: "purpose",
    content: "content",
    howTo: "howto",
  ),
);

final _personal = _item(
  "pbdf.gemeente.personalData",
  "Personal data",
  issueURL: "https://mijn.overheid.example/issue",
  issuer: "Your Municipality",
);

// An NFC-requiring credential (passport), Yivi's own (email) and one issued
// on a website (personal data), in one category.
final _store = [
  CredentialStoreCategory(
    category: "Personal",
    items: [
      _item(
        "pbdf.pbdf.passport",
        "Passport",
        issueURL: "https://passport-issuer.example/issue",
      ),
      _item(
        "pbdf.sidn-pbdf.email",
        "Email",
        issueURL: "https://email-issuer.example/issue",
        issuer: "Yivi",
      ),
      _personal,
    ],
  ),
];

class _Wallet extends SchemalessCredentialOrderController {
  final List<Credential> cards;
  _Wallet(this.cards);

  @override
  Future<List<Credential>> build() async => cards;
}

class _Calls {
  final obtained = <String>[];
  final bridge = RecordingBridge();
  late final IrmaRepository repo;

  Iterable<SessionUserInteractionEvent> get interactions =>
      bridge.dispatched.whereType<SessionUserInteractionEvent>();
}

const _nestedId = 99;

/// The Data tab, stood in for by a page with a "+" that opens the sheet,
/// which is opened.
Future<_Calls> _pump(
  WidgetTester tester, {
  bool? nfcAvailable = true,
  List<CredentialStoreCategory>? store,
  List<Credential> wallet = const [],
  Map<int, Stream<SessionState>> nested = const {},
  List<Override> overrides = const [],
  bool settle = true,
  Size size = const Size(390, 844),
  bool open = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
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
      GoRoute(
        path: "/",
        builder: (context, _) => Scaffold(
          body: Center(
            child: Consumer(
              builder: (context, ref, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    key: const Key("open_add_data"),
                    onPressed: () => showAddDataSheet(context),
                    child: const Text("+"),
                  ),
                  // "Get again" on a card's page.
                  TextButton(
                    key: const Key("obtain_again"),
                    onPressed: () => obtainAgain(
                      context,
                      ref,
                      credentialId: _personal.credential.credentialId,
                      issueUrl: _personal.credential.issueURL,
                    ),
                    child: const Text("again"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
  await pumpTranslated(
    tester,
    ProviderScope(
      overrides: [
        groupedCredentialStoreProvider.overrideWith(
          (ref) => Stream.value(store ?? _store),
        ),
        nfcAvailableProvider.overrideWith(
          (ref) => nfcAvailable == null
              // Never completes: the check stays loading.
              ? Completer<bool>().future
              : Future.value(nfcAvailable),
        ),
        schemalessCredentialOrderControllerProvider.overrideWith(
          () => _Wallet(wallet),
        ),
        irmaRepositoryProvider.overrideWithValue(repo),
        for (final MapEntry(key: id, value: states) in nested.entries)
          sessionStateProvider(id).overrideWith((ref) => states),
        ...overrides,
        // Where "Add" sends the user, recorded instead of opened.
        issuerOpenerProvider.overrideWithValue(
          (context, d, ref) async => calls.obtained.add(d.credentialId),
        ),
      ],
      child: IrmaRepositoryProvider(
        repository: repo,
        child: IrmaTheme(
          builder: (_) => MaterialApp.router(
            routerConfig: router,
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
  if (!open) return calls;
  await tester.tap(find.byKey(const Key("open_add_data")));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await _pumpFor(tester);
  }
  return calls;
}

final _sheet = find.byKey(const Key("add_data_sheet"));

Finder _row(String credentialId) => find.byWidgetPredicate(
  (w) => w is AddDataRow && w.item.credential.credentialId == credentialId,
);

const _nfcHint =
    "Requires NFC, which this device does not support. This credential cannot be loaded.";

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

void main() {
  group("the list", () {
    testWidgets("is a sheet: its title, the search field and the groups", (
      tester,
    ) async {
      await _pump(tester);
      expect(_sheet, findsOneWidget);
      expect(find.text("Adding data"), findsOneWidget);
      expect(find.byKey(const Key("add_data_search")), findsOneWidget);
      expect(find.text("Choose the data you wish to add"), findsOneWidget);
      expect(_row("pbdf.pbdf.passport"), findsOneWidget);
      expect(_row("pbdf.sidn-pbdf.email"), findsOneWidget);
    });

    testWidgets("search narrows the list to matching names and issuers", (
      tester,
    ) async {
      await _pump(tester);
      await tester.enterText(find.byKey(const Key("add_data_search")), "pass");
      await tester.pump();
      expect(_row("pbdf.pbdf.passport"), findsOneWidget);
      expect(_row("pbdf.sidn-pbdf.email"), findsNothing);

      await tester.enterText(
        find.byKey(const Key("add_data_search")),
        "municipality",
      );
      await tester.pump();
      expect(_row("pbdf.gemeente.personalData"), findsOneWidget);

      await tester.enterText(find.byKey(const Key("add_data_search")), "zzz");
      await tester.pump();
      expect(find.text("No data found for “zzz”"), findsOneWidget);
    });

    testWidgets("a type already in the app says so", (tester) async {
      await _pump(
        tester,
        wallet: [
          testCredential(
            type: "pbdf.sidn-pbdf.email",
            hash: "mine",
            name: "Email",
          ),
        ],
      );
      expect(
        find.descendant(
          of: _row("pbdf.sidn-pbdf.email"),
          matching: find.text("In your app"),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _row("pbdf.pbdf.passport"),
          matching: find.text("In your app"),
        ),
        findsNothing,
      );
    });

    testWidgets("staging and demo credentials under their own headers", (
      tester,
    ) async {
      await _pump(
        tester,
        store: [
          ..._store,
          CredentialStoreCategory(
            category: "",
            items: [_item("pbdf-staging.sidn-pbdf.email", "Email")],
            source: CredentialStoreSource.staging,
          ),
          CredentialStoreCategory(
            category: "",
            items: [_item("irma-demo.gemeente.address", "Address")],
            source: CredentialStoreSource.demo,
          ),
        ],
      );
      expect(find.text("Staging (test environment)"), findsOneWidget);
      expect(find.text("Demo (example data)"), findsOneWidget);
    });
  });

  group("NFC", () {
    testWidgets("without NFC a document is greyed out, with the reason", (
      tester,
    ) async {
      await _pump(tester, nfcAvailable: false);
      final passport = tester.widget<AddDataRow>(_row("pbdf.pbdf.passport"));
      expect(passport.nfcBlocked, isTrue);
      expect(
        find.descendant(
          of: _row("pbdf.pbdf.passport"),
          matching: find.text(_nfcHint),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _row("pbdf.pbdf.passport"),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.hint == _nfcHint,
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<AddDataRow>(_row("pbdf.sidn-pbdf.email")).nfcBlocked,
        isFalse,
      );

      // A tap explains instead of opening the details.
      await tester.tap(find.byKey(const Key("pbdf.pbdf.passport_tile")));
      await tester.pumpAndSettle();
      expect(find.text("NFC not supported"), findsOneWidget);
      expect(find.text("1 of 3"), findsNothing);
    });

    testWidgets("enabled with NFC, and while the check is loading", (
      tester,
    ) async {
      await _pump(tester, nfcAvailable: null, settle: false);
      expect(
        tester.widget<AddDataRow>(_row("pbdf.pbdf.passport")).nfcBlocked,
        isFalse,
      );
    });
  });

  group("adding in the sheet", () {
    final personalCard = testCredential(
      type: "pbdf.gemeente.personalData",
      hash: "issued-personal",
      name: "Personal data",
      issuerName: "Your Municipality",
    );
    SessionState issuance(SessionStatus status) => SessionState(
      id: _nestedId,
      protocol: "irma",
      type: SessionType.issuance,
      status: status,
      requestor: _party("Your Municipality"),
      offeredCredentials: [personalCard],
    );

    testWidgets("a row opens its details as a subpage, the card as the tag", (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(
        find.byKey(const Key("pbdf.gemeente.personalData_tile")),
      );
      await tester.pumpAndSettle();

      expect(find.text("1 of 3"), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key("issue_sheet_progress_tag")),
          matching: find.text("Personal data"),
        ),
        findsOneWidget,
      );
      expect(find.text("Example"), findsOneWidget);
      // Not during a request: no note about sharing only what is asked.
      expect(find.textContaining("you will only share"), findsNothing);
      // Issued on a website: said before leaving.
      expect(find.byKey(const Key("sheet_external_note")), findsOneWidget);

      // Back returns to the list, and closing never asked.
      await tester.tap(find.bySemanticsLabel("Go back"));
      await tester.pumpAndSettle();
      expect(_row("pbdf.pbdf.passport"), findsOneWidget);
      expect(find.text("1 of 3"), findsNothing);
    });

    /// The sheet on the personal data's details, its website opened.
    Future<(_Calls, StreamController<SessionState>)> openWebsite(
      WidgetTester tester, {
      List<Credential> wallet = const [],
      Size size = const Size(390, 844),
    }) async {
      final nested = StreamController<SessionState>();
      addTearDown(nested.close);
      final calls = await _pump(
        tester,
        nested: {_nestedId: nested.stream},
        wallet: wallet,
        size: size,
      );
      await tester.tap(
        find.byKey(const Key("pbdf.gemeente.personalData_tile")),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await tester.pumpAndSettle();
      return (calls, nested);
    }

    /// The issuer's pointer as the user comes back: the session starts and
    /// goes to the sheet waiting for it (no request waits).
    void comeBack(WidgetTester tester) {
      final host = ProviderScope.containerOf(
        tester.element(_sheet),
      ).read(nestedIssuanceHostProvider);
      expect(host, isNotNull);
      expect(host!.underlyingSessionId, isNull);
      expect(
        hostForNewSession(host, hasUnderlying: false, isActive: (_) => false),
        host,
      );
      host.attach(_nestedId);
    }

    Future<(_Calls, StreamController<SessionState>)> toSuccess(
      WidgetTester tester, {
      List<Credential> wallet = const [],
      Size size = const Size(390, 844),
    }) async {
      final (calls, nested) = await openWebsite(
        tester,
        wallet: wallet,
        size: size,
      );
      comeBack(tester);
      nested.add(issuance(SessionStatus.requestPermission));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_issue_add")));
      await tester.pump();
      nested.add(issuance(SessionStatus.success));
      await tester.pumpAndSettle();
      return (calls, nested);
    }

    testWidgets("the website opens; the issuance comes back as step 3", (
      tester,
    ) async {
      final (calls, nested) = await openWebsite(tester);
      expect(calls.obtained, ["pbdf.gemeente.personalData"]);
      expect(find.text("2 of 3"), findsOneWidget);
      expect(find.byKey(const Key("sheet_opened_note")), findsOneWidget);
      expect(find.byKey(const Key("sheet_external_note")), findsNothing);

      comeBack(tester);
      nested.add(issuance(SessionStatus.requestPermission));
      await tester.pumpAndSettle();
      expect(find.text("3 of 3"), findsOneWidget);
      expect(
        find.text("Do you want to add this data to your Yivi app?"),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key("sheet_issue_add")));
      await tester.pump();
      final granted = calls.interactions.last;
      expect(
        (granted.sessionId, granted.type),
        (_nestedId, UserInteractionType.permission),
      );
    });

    testWidgets("Success: Add more and Done, nothing waits any more", (
      tester,
    ) async {
      await toSuccess(tester);
      expect(find.text("Done"), findsWidgets);
      expect(
        find.text("Personal data has been added to Yivi."),
        findsOneWidget,
      );
      expect(find.byKey(const Key("sheet_add_more")), findsOneWidget);
      expect(find.byKey(const Key("sheet_done")), findsOneWidget);
      expect(
        ProviderScope.containerOf(
          tester.element(_sheet),
        ).read(nestedIssuanceHostProvider),
        isNull,
      );
    });

    testWidgets("Add more goes back to the list, which says what was added", (
      tester,
    ) async {
      await toSuccess(tester);
      await tester.tap(find.byKey(const Key("sheet_add_more")));
      await tester.pumpAndSettle();
      expect(_row("pbdf.pbdf.passport"), findsOneWidget);
      expect(
        find.text("Personal data added. Add something else?"),
        findsOneWidget,
      );
      // Closing now does not ask.
      await tester.tap(find.bySemanticsLabel("Close"));
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
    });

    testWidgets("Done closes the sheet", (tester) async {
      await toSuccess(tester);
      await tester.tap(find.byKey(const Key("sheet_done")));
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
    });

    testWidgets("tablet: Done opens the new card in the detail pane", (
      tester,
    ) async {
      await toSuccess(
        tester,
        wallet: [personalCard],
        size: const Size(1180, 820),
      );
      await tester.tap(find.byKey(const Key("sheet_done")));
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
      expect(
        ProviderScope.containerOf(
          tester.element(find.byKey(const Key("open_add_data"))),
        ).read(selectedCardProvider),
        personalCard.hash,
      );
    });

    testWidgets("closing asks once adding has started, not before", (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(
        find.byKey(const Key("pbdf.gemeente.personalData_tile")),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel("Close"));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("sheet_stop_dialog")), findsOneWidget);
      expect(
        find.text("What you entered so far is lost and nothing is added."),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key("sheet_stop_confirm")));
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
    });
  });

  testWidgets("Get again opens the sheet on the type's details", (
    tester,
  ) async {
    await _pump(tester, open: false);
    await tester.tap(find.byKey(const Key("obtain_again")));
    await tester.pumpAndSettle();
    expect(_sheet, findsOneWidget);
    expect(find.text("1 of 3"), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key("issue_sheet_progress_tag")),
        matching: find.text("Personal data"),
      ),
      findsOneWidget,
    );
    // Back goes to the whole list.
    await tester.tap(find.bySemanticsLabel("Go back"));
    await tester.pumpAndSettle();
    expect(_row("pbdf.pbdf.passport"), findsOneWidget);
  });

  testWidgets("an e-mail address: the address step in the sheet", (
    tester,
  ) async {
    await _pump(
      tester,
      overrides: [emailIssuerApiProvider.overrideWithValue(_FakeEmailApi())],
    );
    await tester.tap(find.byKey(const Key("pbdf.sidn-pbdf.email_tile")));
    await tester.pumpAndSettle();
    // Yivi's own: no note about leaving for a website.
    expect(find.byKey(const Key("sheet_external_note")), findsNothing);
    await tester.tap(find.byKey(const Key("sheet_go_button")));
    await _pumpFor(tester);
    expect(find.text("Add email address"), findsOneWidget);
    expect(find.text("2 of 4"), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key("issue_sheet_progress_tag")),
        matching: find.text("Email"),
      ),
      findsOneWidget,
    );
  });

  for (final (credentialId, documentType) in [
    ("pbdf.pbdf.passport", DocumentType.passport),
    ("pbdf.pbdf.idcard", DocumentType.identityCard),
    ("pbdf.pbdf.drivinglicence", DocumentType.drivingLicence),
  ]) {
    testWidgets("$credentialId: its details first, then its instruction", (
      tester,
    ) async {
      await _pump(
        tester,
        store: [
          CredentialStoreCategory(
            category: "Documents",
            items: [
              _item(
                credentialId,
                "Document",
                issueURL: "https://document-issuer.example/issue",
              ),
            ],
          ),
        ],
      );
      await tester.tap(find.byKey(Key("${credentialId}_tile")));
      await tester.pumpAndSettle();
      expect(find.text("1 of 5"), findsOneWidget);
      expect(find.byType(DocumentInstructionScreen), findsNothing);

      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await _pumpFor(tester);
      final screen = tester.widget<DocumentInstructionScreen>(
        find.descendant(
          of: _sheet,
          matching: find.byType(DocumentInstructionScreen),
        ),
      );
      expect(screen.documentType, documentType);
    });
  }
}

/// The e-mail issuer, faked: sending always works; any code gives a session.
class _FakeEmailApi implements EmailIssuerApi {
  @override
  Future<void> sendEmail({
    required String emailAddress,
    required String language,
  }) async {}

  @override
  Future<SessionPointer> verifyCode({
    required String email,
    required String verificationCode,
  }) async => SessionPointer(
    u: "https://irma.example/session/abc",
    irmaqr: "issuing",
    protocol: Protocol.irma,
    continueOnSecondDevice: true,
  );
}
