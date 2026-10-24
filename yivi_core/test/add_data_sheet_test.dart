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
import "package:yivi_core/src/widgets/credential_card/credential_type_thumbnail.dart";
import "package:yivi_core/src/widgets/glass/glass_search_field.dart";
import "package:yivi_core/src/widgets/glass/sheet_action_row.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";
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
    testWidgets("is a sheet: its title and the groups, no search", (
      tester,
    ) async {
      await _pump(tester);
      expect(_sheet, findsOneWidget);
      expect(find.text("Adding data"), findsOneWidget);
      expect(find.byType(GlassSearchField), findsNothing);
      // Each type as its card, not a round logo.
      expect(
        find.descendant(
          of: _row("pbdf.pbdf.passport"),
          matching: find.byType(CredentialTypeThumbnail),
        ),
        findsOneWidget,
      );
      expect(_row("pbdf.pbdf.passport"), findsOneWidget);
      expect(_row("pbdf.sidn-pbdf.email"), findsOneWidget);
    });

    testWidgets("a long list builds only the rows on screen", (tester) async {
      await _pump(
        tester,
        store: [
          CredentialStoreCategory(
            category: "Personal",
            items: [
              for (var i = 0; i < 200; i++)
                _item(
                  "irma-demo.x.card$i",
                  "Card ${i.toString().padLeft(3, "0")}",
                ),
            ],
          ),
        ],
      );
      final built = find.byType(AddDataRow).evaluate().length;
      expect(built, greaterThan(0));
      expect(built, lessThan(40));
      // The last one comes when it scrolls into view.
      expect(_row("irma-demo.x.card199"), findsNothing);
      await tester.scrollUntilVisible(
        _row("irma-demo.x.card199"),
        600,
        // The list's own, not a sideways one inside a row.
        scrollable: find
            .descendant(
              of: _sheet,
              matching: find.byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              ),
            )
            .first,
      );
      expect(_row("irma-demo.x.card199"), findsOneWidget);
    });

    testWidgets("a bitmap logo on the card is decoded at its size", (
      tester,
    ) async {
      // A 1x1 PNG.
      const png =
          "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";
      await _pump(
        tester,
        store: [
          CredentialStoreCategory(
            category: "Personal",
            items: [
              CredentialStoreItem(
                credential: CredentialDescriptor(
                  credentialId: "irma-demo.x.logo",
                  name: "With a logo",
                  issuer: _party("Issuer"),
                  category: "Personal",
                  image: LogoImage(base64: png, mimeType: "image/png"),
                  attributes: const [],
                  issueURL: null,
                ),
                faq: Faq(intro: "", purpose: "", content: "", howTo: ""),
              ),
            ],
          ),
        ],
      );
      final image = tester.widget<Image>(
        find.descendant(
          of: _row("irma-demo.x.logo"),
          matching: find.byType(Image),
        ),
      );
      expect(image.image, isA<ResizeImage>());
      expect((image.image as ResizeImage).width, 40);
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
      // A check on the card, and said to screen readers.
      expect(
        find.byKey(const Key("pbdf.sidn-pbdf.email_owned_check")),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key("pbdf.pbdf.passport_owned_check")),
        findsNothing,
      );
      expect(
        tester.getSemantics(_row("pbdf.sidn-pbdf.email")).label,
        contains("In your app"),
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

  testWidgets("a document: its issuer as its subtitle, no word of NFC", (
    tester,
  ) async {
    await _pump(tester);
    expect(
      tester
          .widget<Text>(find.byKey(const Key("pbdf.pbdf.passport_subtitle")))
          .data,
      "Issuer",
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key("pbdf.sidn-pbdf.email_subtitle")))
          .data,
      isNot(contains("NFC")),
    );
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
        tester.getSemantics(_row("pbdf.pbdf.passport")).label,
        contains(_nfcHint),
      );
      expect(
        tester.widget<AddDataRow>(_row("pbdf.sidn-pbdf.email")).nfcBlocked,
        isFalse,
      );

      // A tap explains instead of opening the details.
      await tester.tap(find.byKey(const Key("pbdf.pbdf.passport_tile")));
      await tester.pumpAndSettle();
      expect(find.text("NFC not supported"), findsOneWidget);
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 1, 3))),
        findsNothing,
      );
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

      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 1, 3))),
        findsOneWidget,
      );
      // The card's name is the bar's title; no tag, no requestor line.
      expect(find.text("Personal data"), findsWidgets);
      expect(find.byKey(const Key("issue_sheet_for_requestor")), findsNothing);
      expect(find.byKey(const Key("add_data_details_name")), findsOneWidget);
      // Not during a request: no note about sharing only what is asked.
      expect(find.textContaining("you will only share"), findsNothing);
      // Issued on a website: said before leaving, at the foot of the
      // details; the way on is the button at the bottom.
      expect(find.byKey(const Key("sheet_external_note")), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SheetBottomBar),
          matching: find.byKey(const Key("sheet_go_button")),
        ),
        findsOneWidget,
      );

      // Back returns to the list, and closing never asked.
      await tester.tap(find.bySemanticsLabel("Go back"));
      await tester.pumpAndSettle();
      expect(_row("pbdf.pbdf.passport"), findsOneWidget);
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 1, 3))),
        findsNothing,
      );
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
      // Step 2 says where adding goes; its way on opens the website.
      await tester.tap(find.byKey(const Key("sheet_open_website")));
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

    for (final (name, size, inBar) in [
      ("upright", const Size(390, 844), false),
      ("sideways", const Size(874, 402), true),
      ("on a tablet", const Size(820, 1180), true),
    ]) {
      testWidgets("$name: Add first shows where adding goes, step 2; its way "
          "on opens the website", (tester) async {
        final calls = await _pump(tester, size: size);
        await tester.tap(
          find.byKey(const Key("pbdf.gemeente.personalData_tile")),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key("sheet_go_button")));
        await tester.pumpAndSettle();
        // Nothing opened yet: the page says where adding goes.
        expect(calls.obtained, isEmpty);
        expect(find.byKey(const Key("sheet_website_heading")), findsOneWidget);
        expect(find.byKey(const Key("sheet_website_host")), findsOneWidget);
        expect(
          find.byKey(const ValueKey(("issue_sheet_progress", 2, 3))),
          findsOneWidget,
        );
        final open = tester.getRect(
          find.byKey(const Key("sheet_open_website")),
        );
        final title = tester.getRect(
          find.byKey(const Key("glass_sheet_title")).last,
        );
        // At the bottom upright; in the bar sideways and on a tablet.
        if (inBar) {
          expect(open.center.dy, closeTo(title.center.dy, 2));
        } else {
          expect(open.top, greaterThan(size.height - 120));
        }
        await tester.tap(find.byKey(const Key("sheet_open_website")));
        await tester.pumpAndSettle();
        expect(calls.obtained, ["pbdf.gemeente.personalData"]);
        expect(find.byKey(const Key("sheet_opened_note")), findsOneWidget);
        expect(find.text("Open again"), findsOneWidget);
      });
    }

    testWidgets("back from the website page, before it opened: the details, "
        "without asking", (tester) async {
      await _pump(tester);
      await tester.tap(
        find.byKey(const Key("pbdf.gemeente.personalData_tile")),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel("Go back").last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("sheet_stop_dialog")), findsNothing);
      expect(find.byKey(const Key("sheet_website_heading")), findsNothing);
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 1, 3))),
        findsOneWidget,
      );
    });

    testWidgets("Success says so in the bar", (tester) async {
      await toSuccess(tester);
      expect(
        tester
            .widget<Text>(find.byKey(const Key("glass_sheet_title")).last)
            .data,
        "Success",
      );
    });

    testWidgets("Success comes in as a page of its own, from the right", (
      tester,
    ) async {
      final (_, nested) = await openWebsite(tester);
      comeBack(tester);
      nested.add(issuance(SessionStatus.requestPermission));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_issue_add")));
      await tester.pump();
      nested.add(issuance(SessionStatus.success));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      // Half way: the offer goes out to the left as Success comes in.
      final added = tester.getRect(find.byKey(const Key("sheet_added_text")));
      expect(added.left, greaterThan(40));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const Key("sheet_added_text"))).left,
        lessThan(added.left),
      );
    });

    testWidgets("the website opens; the issuance comes back as step 3", (
      tester,
    ) async {
      final (calls, nested) = await openWebsite(tester);
      expect(calls.obtained, ["pbdf.gemeente.personalData"]);
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 2, 3))),
        findsOneWidget,
      );
      expect(find.byKey(const Key("sheet_opened_note")), findsOneWidget);
      expect(find.byKey(const Key("sheet_external_note")), findsNothing);

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
        (_nestedId, UserInteractionType.permission),
      );
    });

    testWidgets("Success: Add more and Done, nothing waits any more", (
      tester,
    ) async {
      await toSuccess(tester);
      expect(find.text("Done"), findsWidgets);
      expect(find.text("Added"), findsOneWidget);
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

    testWidgets("the list has its close button at the top left; the "
        "details none, only the way on at the top right", (tester) async {
      await _pump(tester);
      final close = tester.getRect(find.byType(IrmaCloseButton));
      final title = tester.getRect(
        find.byKey(const Key("glass_sheet_title")).last,
      );
      expect(close.right, lessThan(title.left));
      await tester.tap(
        find.byKey(const Key("pbdf.gemeente.personalData_tile")),
      );
      await tester.pumpAndSettle();
      // Back at the left; no close button on the details (the list under
      // them keeps its own, hidden).
      expect(find.byType(IrmaCloseButton).hitTestable(), findsNothing);
      expect(find.bySemanticsLabel("Go back"), findsWidgets);
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

      // No close button on the step: a drag down on its header closes.
      expect(find.byType(IrmaCloseButton), findsNothing);
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(const Key("glass_sheet_title")).last),
      );
      for (var i = 0; i < 10; i++) {
        await g.moveBy(const Offset(0, 50));
        await tester.pump();
      }
      await g.up();
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

    group("sideways", () {
      const side = Size(874, 402);

      /// The rect of the sheet's bar: its title.
      Rect title(WidgetTester tester) =>
          tester.getRect(find.byKey(const Key("glass_sheet_title")).last);

      testWidgets("details: Add in the bar at the right, the card at the "
          "left, what you get and the website note at the right", (
        tester,
      ) async {
        await _pump(tester, size: side);
        await tester.tap(
          find.byKey(const Key("pbdf.gemeente.personalData_tile")),
        );
        await tester.pumpAndSettle();
        final go = tester.getRect(find.byKey(const Key("sheet_go_button")));
        final bar = title(tester);
        // In the bar, after the title, before the close button.
        expect(go.center.dy, closeTo(bar.center.dy, 2));
        expect(go.left, greaterThan(bar.right));
        expect(find.byType(SheetBottomBar), findsNothing);
        final youGet = tester.getRect(
          find.byKey(const Key("add_data_you_get")),
        );
        expect(youGet.top, greaterThan(go.bottom));
        // Where "Add" goes: at the foot of what you get.
        final note = tester.getRect(
          find.byKey(const Key("sheet_external_note")),
        );
        expect(note.left, greaterThanOrEqualTo(youGet.left - 8));
        // The progress: a line under the bar, no count.
        expect(find.text("1 of 3"), findsNothing);
        expect(
          find.byKey(const ValueKey(("issue_sheet_progress", 1, 3))),
          findsOneWidget,
        );
      });

      testWidgets("opened: the note at the right, Open again in the bar", (
        tester,
      ) async {
        await openWebsite(tester, size: side);
        // The website page: its way on (Open again) in the bar.
        final go = tester.getRect(find.byKey(const Key("sheet_open_website")));
        final opened = tester.getRect(
          find.byKey(const Key("sheet_opened_note")),
        );
        expect(go.center.dy, closeTo(title(tester).center.dy, 2));
        expect(opened.top, greaterThan(go.bottom));
        expect(find.text("Open again"), findsOneWidget);
        expect(
          find.byKey(const ValueKey(("issue_sheet_progress", 2, 3))),
          findsOneWidget,
        );
        // The issuer's pointer as the user comes back: the session is
        // followed (and its stream can close).
        comeBack(tester);
        await tester.pump();
      });

      testWidgets("added: Done in the bar, no close button; the card and "
          "the words at the left, what is in the app at the right", (
        tester,
      ) async {
        await toSuccess(tester, size: side);
        final done = tester.getRect(find.byKey(const Key("sheet_done")));
        expect(done.center.dy, closeTo(title(tester).center.dy, 2));
        expect(find.byType(IrmaCloseButton), findsNothing);
        final values = tester.getRect(
          find.byKey(const Key("sheet_added_values")),
        );
        final added = tester.getRect(find.byKey(const Key("sheet_added_text")));
        expect(values.left, greaterThan(added.right));
        expect(
          find.descendant(
            of: find.byKey(const Key("sheet_added_values")),
            matching: find.text("In your app"),
          ),
          findsOneWidget,
        );
        // "Add more" is a link under what is in the app.
        expect(
          find.descendant(
            of: find.byKey(const Key("sheet_added_values")),
            matching: find.byKey(const Key("sheet_add_more")),
          ),
          findsOneWidget,
        );
      });
    });
  });

  testWidgets("Get again opens the sheet on the type's details", (
    tester,
  ) async {
    await _pump(tester, open: false);
    await tester.tap(find.byKey(const Key("obtain_again")));
    await tester.pumpAndSettle();
    expect(_sheet, findsOneWidget);
    expect(
      find.byKey(const ValueKey(("issue_sheet_progress", 1, 3))),
      findsOneWidget,
    );
    // The card's name is the bar's title.
    expect(find.text("Personal data"), findsWidgets);
    // The details are the sheet's first page: no back button, and a swipe
    // does not go back to the list.
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
    expect(_row("pbdf.pbdf.passport"), findsNothing);
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
    expect(
      find.byKey(const ValueKey(("issue_sheet_progress", 2, 4))),
      findsOneWidget,
    );
    // Not for a request: no line saying who it is for.
    expect(find.byKey(const Key("issue_sheet_for_requestor")), findsNothing);
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
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 1, 5))),
        findsOneWidget,
      );
      expect(find.byType(DocumentInstructionScreen), findsNothing);

      final add = tester.getRect(find.byKey(const Key("sheet_go_button")));
      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await _pumpFor(tester);
      final screen = tester.widget<DocumentInstructionScreen>(
        find.descendant(
          of: _sheet,
          matching: find.byType(DocumentInstructionScreen),
        ),
      );
      expect(screen.documentType, documentType);
      // Start is the sheet's own button, where "Add" was: in the page's
      // bottom bar, not in the instruction screen.
      final startButton = find.descendant(
        of: _sheet,
        matching: find.byKey(const Key("bottom_bar_primary")),
      );
      expect(
        find.descendant(
          of: find.byType(DocumentInstructionScreen),
          matching: find.byKey(const Key("bottom_bar_primary")),
        ),
        findsNothing,
      );
      expect(tester.getRect(startButton), add);

      // On to typing it in: the bar stays put while the screen slides in;
      // only its labels change.
      await tester.tap(startButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final next = find.descendant(
        of: _sheet,
        matching: find.byKey(const Key("bottom_bar_primary")),
      );
      expect(next, findsOneWidget);
      expect(tester.getRect(next), add);
      await _pumpFor(tester);
      expect(tester.getRect(next), add);
    });
  }

  group("sideways", () {
    const side = Size(874, 402);

    testWidgets("the list: two cards side by side", (tester) async {
      await _pump(tester, size: side);
      expect(find.byType(GlassSearchField), findsNothing);
      final passport = tester.getRect(_row("pbdf.pbdf.passport"));
      final email = tester.getRect(_row("pbdf.sidn-pbdf.email"));
      expect(email.top, passport.top);
      expect(email.left, greaterThan(passport.right));
      expect(find.text("Adding data"), findsOneWidget);
    });

    testWidgets("an e-mail address: Send code in the bar, the field at the "
        "right", (tester) async {
      await _pump(
        tester,
        size: side,
        overrides: [emailIssuerApiProvider.overrideWithValue(_FakeEmailApi())],
      );
      await tester.tap(find.byKey(const Key("pbdf.sidn-pbdf.email_tile")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await _pumpFor(tester);
      final send = tester.getRect(find.byKey(const Key("contact_sheet_send")));
      final field = tester.getRect(find.byKey(const Key("email_input_field")));
      final title = tester.getRect(
        find.byKey(const Key("glass_sheet_title")).last,
      );
      expect(send.left, greaterThan(title.right));
      expect(field.top, greaterThan(send.bottom));
      // The explanation at the left (280 wide), the field at the right.
      expect(field.left, greaterThanOrEqualTo(20 + 280 + 28));
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 2, 4))),
        findsOneWidget,
      );
      expect(find.byType(SheetBottomBar), findsNothing);
    });

    testWidgets("a passport: Start in the bar, the words at the left, the "
        "picture at the right", (tester) async {
      await _pump(
        tester,
        size: side,
        store: [
          CredentialStoreCategory(
            category: "Documents",
            items: [
              _item(
                "pbdf.pbdf.passport",
                "Passport",
                issueURL: "https://document-issuer.example/issue",
              ),
            ],
          ),
        ],
      );
      await tester.tap(find.byKey(const Key("pbdf.pbdf.passport_tile")));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("sheet_go_button")));
      await _pumpFor(tester);
      final picture = tester.getRect(
        find.byKey(const Key("document_instruction_picture")),
      );
      // The screen's Start goes in the sheet's bar, after its title.
      final start = tester.getRect(find.byKey(const Key("bottom_bar_primary")));
      final bar = tester.getRect(
        find.byKey(const Key("glass_sheet_title")).last,
      );
      final title = tester.getRect(
        find.text("Open your passport on the photo page"),
      );
      expect(start.left, greaterThan(bar.right));
      expect(start.bottom, lessThan(picture.top));
      expect(title.right, lessThan(picture.left));
      expect(
        find.byKey(const ValueKey(("issue_sheet_progress", 2, 5))),
        findsOneWidget,
      );
    });
  });
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
