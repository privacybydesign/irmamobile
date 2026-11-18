// Layout checks against the document flow boards of the redesign canvas
// (AppDocument: instruction, camera, manual entry, the NFC stages, the face
// check intro and the permission; numbered G1 to G9 after the earlier boards
// they replace). Each test names the board it follows.
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/models/log_entry.dart" show CredentialFormat;
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_instruction_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/face_verification_intro_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/document_flow_footer.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/face_frame_illustration.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/nfc_stage_pictures.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/nfc_stage_view.dart";
import "package:yivi_core/src/screens/session/issuance/document_issuance_permission.dart";
import "package:yivi_core/src/screens/session/issuance/issuance_permission.dart";
import "package:yivi_core/src/util/test_detection.dart";
import "package:yivi_core/src/widgets/feedback/done_check.dart";

import "support/document_screen_host.dart";
import "support/pump_translated.dart";
import "support/test_app.dart";

/// Whether the animations that loop on a timer run.
enum _Ticker { stopped, running }

/// What an age attribute says about the holder.
enum _Over { yes, no }

const _phone = Size(390, 844);
const _dutch = Locale("nl", "NL");

const _textColor = Color(0xFF484747);

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Locale locale = const Locale("en", "US"),
  _Ticker ticker = .stopped,
}) async {
  // The document screens as the sheet shows them; the looping pictures
  // (motion tests) on their own.
  tester.view
    ..physicalSize = _phone
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Widget app = testApp(
    ticker == .running ? home : DocumentScreenHost(home),
    locale: locale,
  );
  // TestContext stops the animations that loop on a timer, so that
  // pumpAndSettle can finish.
  if (ticker == .stopped) app = TestContext(child: app);

  await pumpTranslated(tester, ProviderScope(child: app));
  // A looping animation never settles.
  ticker == .running ? await tester.pump() : await tester.pumpAndSettle();
}

Finder _primary() => find.byKey(const Key("bottom_bar_primary"));
Finder _secondary() => find.byKey(const Key("bottom_bar_secondary"));

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  group("G1 · how to hold the passport", () {
    Future<void> pumpScreen(WidgetTester tester) => _pump(
      tester,
      DocumentInstructionScreen(
        documentType: DocumentType.passport,
        onStart: () {},
      ),
      locale: _dutch,
    );

    testWidgets("the picture is 320 by 256, the title 28 below it", (
      tester,
    ) async {
      await pumpScreen(tester);

      final picture = tester.getRect(
        find.byKey(const Key("document_instruction_picture")),
      );
      expect(picture.size, const Size(320, 256));
      // 24 below the top of the page, centred.
      expect(
        picture.top,
        tester.getTopLeft(find.byType(DocumentInstructionScreen)).dy + 24,
      );
      expect(picture.center.dx, _phone.width / 2);
      expect(
        tester
            .getTopLeft(
              find.text("Open je paspoort op de pagina met je pasfoto"),
            )
            .dy,
        picture.bottom + 28,
      );
    });

    testWidgets("Dutch copy, heading 24 bold, the tip 14 in dark blue", (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(
        find.text(
          "Houd je paspoort voor de camera en zorg dat de hele pagina goed "
          "zichtbaar is. Druk daarna op Start om te beginnen.",
        ),
        findsOneWidget,
      );
      final heading = _styleOf(
        tester,
        "Open je paspoort op de pagina met je pasfoto",
      );
      expect(heading.fontSize, 24);
      expect(heading.fontWeight, FontWeight.w700);
      expect(heading.height, 30 / 24);

      final tip = _styleOf(
        tester,
        "Leg het paspoort niet direct onder een lamp, dan geeft het minder "
        "reflectie.",
      );
      expect(tip.fontSize, 14);
      expect(tip.color, const Color(0xFF123254));
    });

    testWidgets("the picture has a text for screen readers", (tester) async {
      await pumpScreen(tester);

      expect(
        find.bySemanticsLabel(
          "Een telefoon boven een open paspoort, met de camera op de twee "
          "regels onderaan de pagina met de pasfoto.",
        ),
        findsOneWidget,
      );
    });
  });

  group("G3 G4 G6 G9 · reading the document", () {
    NfcStageScaffold stage({
      required Widget picture,
      required String title,
      required String body,
      required List<NfcStageAction> actions,
    }) => NfcStageScaffold(
      picture: picture,
      titleKey: title,
      bodyKey: body,
      textParams: const {"document": "paspoort"},
      actions: actions,
    );

    NfcStageAction cancel() => NfcStageAction.secondary(
      labelKey: "document_flow.cancel",
      onPressed: () {},
    );

    testWidgets("G3: picture area 360, phone 300, title 24 bold in grey", (
      tester,
    ) async {
      await _pump(
        tester,
        stage(
          picture: const NfcPhoneOnDocument(
            document: NfcDocumentPicture.passport,
          ),
          title: "document_flow.nfc.waiting_title",
          body: "document_flow.nfc.waiting_body_passport",
          actions: [cancel()],
        ),
        locale: _dutch,
      );

      expect(find.text("Leg je telefoon op je paspoort"), findsOneWidget);
      expect(find.text("Je paspoort mag dicht blijven."), findsOneWidget);
      expect(find.text("Annuleer"), findsOneWidget);

      // 16 below the top of the page, across it.
      final page = tester.getRect(find.byType(NfcStageScaffold));
      expect(
        tester.getRect(find.byKey(const Key("nfc_stage_picture"))),
        Rect.fromLTWH(page.left, page.top + 16, page.width, 360),
      );
      expect(
        tester.getSize(find.byType(NfcPhoneOnDocument)),
        const Size(300, 300),
      );

      final title = _styleOf(tester, "Leg je telefoon op je paspoort");
      expect(title.fontSize, 24);
      expect(title.fontWeight, FontWeight.w700);
      expect(title.height, 30 / 24);
      expect(title.color, _textColor);
      expect(
        tester.getTopLeft(find.text("Leg je telefoon op je paspoort")).dy,
        page.top + 16 + 360 + 24,
      );
      // 12 between the title and the line under it.
      expect(
        tester.getTopLeft(find.text("Je paspoort mag dicht blijven.")).dy,
        tester.getRect(find.text("Leg je telefoon op je paspoort")).bottom + 12,
      );
      expect(_secondary(), findsOneWidget);
    });

    testWidgets("G4: a ring of 240 with the percentage at 44", (tester) async {
      await _pump(
        tester,
        stage(
          picture: const NfcProgressRing(
            progress: 0.62,
            label: "Paspoort lezen",
          ),
          title: "document_flow.nfc.reading_title",
          body: "document_flow.nfc.reading_body",
          actions: [cancel()],
        ),
        locale: _dutch,
      );

      expect(find.text("Niet bewegen"), findsOneWidget);
      expect(find.text("Je paspoort wordt gelezen."), findsOneWidget);
      expect(
        tester.getSize(find.byType(NfcProgressRing)),
        const Size(240, 240),
      );

      final percent = _styleOf(tester, "62%");
      expect(percent.fontSize, 44);
      expect(percent.fontWeight, FontWeight.w700);
      expect(percent.color, _textColor);
      expect(
        percent.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    testWidgets("G6: a 180 check, and the bar keeps its "
        "height", (tester) async {
      await _pump(
        tester,
        stage(
          picture: const DoneCheck(),
          title: "document_flow.nfc.done_title",
          body: "document_flow.nfc.done_body",
          actions: const [],
        ),
        locale: _dutch,
      );

      expect(find.text("Je paspoort is gelezen"), findsOneWidget);
      expect(find.text("Je kunt je telefoon weer oppakken."), findsOneWidget);
      expect(tester.getSize(find.byType(DoneCheck)), const Size(180, 180));
      // No button: the page's bottom bar keeps its room itself.
      expect(_primary(), findsNothing);
      expect(_secondary(), findsNothing);
    });

    testWidgets("G9: NFC off, 220 picture, two buttons", (tester) async {
      await _pump(
        tester,
        stage(
          picture: const NfcOffIllustration(),
          title: "document_flow.nfc.off_title",
          body: "document_flow.nfc.off_body",
          actions: [
            NfcStageAction.primary(
              labelKey: "document_flow.nfc.open_settings",
              onPressed: () {},
            ),
            cancel(),
          ],
        ),
        locale: _dutch,
      );

      expect(find.text("Zet NFC aan"), findsOneWidget);
      expect(
        find.text("Daarmee leest je telefoon de chip in je paspoort."),
        findsOneWidget,
      );
      expect(find.text("Open NFC-instellingen"), findsOneWidget);
      expect(
        tester.getSize(find.byType(NfcOffIllustration)),
        const Size(220, 220),
      );
      expect(_primary(), findsOneWidget);
      expect(_secondary(), findsOneWidget);
    });

    testWidgets("the picture area is the same height in every state", (
      tester,
    ) async {
      for (final picture in [
        const NfcPhoneOnDocument(document: NfcDocumentPicture.passport),
        const NfcProgressRing(progress: 0.5, label: "x"),
        const DoneCheck(),
        const NfcOffIllustration(),
      ]) {
        await _pump(
          tester,
          stage(
            picture: picture,
            title: "document_flow.nfc.reading_title",
            body: "document_flow.nfc.reading_body",
            actions: const [],
          ),
        );
        expect(
          tester.getSize(find.byKey(const Key("nfc_stage_picture"))).height,
          360,
        );
      }
    });
  });

  group("the buttons", () {
    testWidgets("a label that wraps at a large text size makes the button "
        "taller", (tester) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: Scaffold(
              body: Center(
                child: DocumentFlowButton(
                  labelKey: "document_flow.nfc.open_settings",
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
        locale: _dutch,
      );

      final label = tester.getRect(find.text("Open NFC-instellingen"));
      final button = tester.getRect(find.byType(DocumentFlowButton));

      expect(button.height, greaterThan(DocumentFlowButton.height));
      expect(label.height, lessThanOrEqualTo(button.height));
    });

    testWidgets("a button without an action is announced as disabled", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        const Scaffold(
          body: Center(
            child: DocumentFlowButton(
              labelKey: "document_flow.cancel",
              onPressed: null,
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(DocumentFlowButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      semantics.dispose();
    });
  });

  group("motion", () {
    testWidgets("G3: the phone loops, and rests when the system asks for "
        "less motion", (tester) async {
      Future<void> pumpPhone() => _pump(
        tester,
        const Scaffold(
          body: Center(
            child: NfcPhoneOnDocument(document: NfcDocumentPicture.passport),
          ),
        ),
        ticker: .running,
      );

      await pumpPhone();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpPhone();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets("G6: the check draws once, and is there at once under less "
        "motion", (tester) async {
      Future<void> pumpCheck() => _pump(
        tester,
        const Scaffold(body: Center(child: DoneCheck())),
        ticker: .running,
      );

      await tester.runAsync(() async {});
      await pumpCheck();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpCheck();
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group("G7 · face check intro", () {
    Future<void> pumpIntro(WidgetTester tester) => _pump(
      tester,
      FaceVerificationIntroScreen(onStart: () {}),
      locale: _dutch,
    );

    testWidgets("Dutch copy, a picture of 200, one Start button", (
      tester,
    ) async {
      await pumpIntro(tester);

      expect(find.text("Korte gezichtscontrole"), findsOneWidget);
      const explanation =
          "We doen nu een korte gezichtscontrole om te bevestigen dat jij de "
          "persoon op het document bent.";
      expect(find.text(explanation), findsOneWidget);
      for (final tip in [
        "Richt de selfie camera op je gezicht.",
        "Zorg voor voldoende licht.",
        "Kijk recht in de camera.",
        "Verwijder brillen, hoeden, etc.",
      ]) {
        expect(find.text(tip), findsOneWidget);
      }

      // The 200 face, centred in its 230 high card 16 below the heading.
      final picture = tester.getRect(find.byType(FaceFrameIllustration));
      expect(picture.size, const Size(200, 200));
      expect(
        picture.top,
        tester.getRect(find.text("Korte gezichtscontrole")).bottom + 16 + 15,
      );
      expect(
        tester.getTopLeft(find.text(explanation)).dy,
        picture.bottom + 15 + 20,
      );

      expect(find.text("Start verificatie"), findsOneWidget);
      expect(_secondary(), findsNothing);
      expect(_primary(), findsOneWidget);
    });

    testWidgets("the tips are 12 + 12 apart with a line between, in a group", (
      tester,
    ) async {
      await pumpIntro(tester);

      final first = tester.getRect(
        find.text("Richt de selfie camera op je gezicht."),
      );
      final second = tester.getRect(find.text("Zorg voor voldoende licht."));
      expect(second.top - first.bottom, 12 + 1 + 12);
      // Page padding, the group's padding, the tick and the gap.
      expect(first.left, 16 + 16 + 22 + 12);
    });
  });

  group("G8 · permission for the document", () {
    final issuer = TrustedParty(
      id: "pbdf.pbdf",
      name: "Stichting Privacy by Design",
      url: null,
      parent: null,
      verified: true,
    );

    Attribute text(String claim, String name, String value) => Attribute(
      claimPath: [claim],
      displayName: name,
      value: AttributeValue(type: AttributeType.string, string: value),
    );

    Attribute age(int years, _Over answer) => Attribute(
      claimPath: ["over$years"],
      displayName: "Over $years",
      value: AttributeValue(type: AttributeType.string, string: answer.name),
    );

    Credential credential(String id) {
      return Credential(
        credentialId: id,
        hash: "hash-$id",
        name: "Paspoort",
        issuer: issuer,
        credentialInstanceIds: {},
        batchInstanceCountsRemaining: {CredentialFormat.sdjwtvc: 10},
        attributes: [
          text("documentNumber", "Documentnummer", "SPECI2021"),
          text("firstName", "Voornaam", "Willeke Liselotte"),
          age(12, .yes),
          age(21, .yes),
          age(65, .no),
        ],
        revoked: false,
        revocationSupported: false,
        issueUrl: null,
        expiryDate: DateTime(2031, 8, 2).millisecondsSinceEpoch ~/ 1000,
      );
    }

    Future<void> pumpPermission(
      WidgetTester tester, {
      String id = "pbdf.pbdf.passport",
    }) => _pump(
      tester,
      IssuancePermission(
        issuedCredentials: [credential(id)],
        onGivePermission: () {},
        onDismiss: () {},
      ),
      locale: _dutch,
    );

    testWidgets("a document: the question page, its data as on the board", (
      tester,
    ) async {
      await pumpPermission(tester);

      expect(find.byType(DocumentIssuanceData), findsOneWidget);
      expect(find.byKey(const Key("issuance_heading")), findsOneWidget);
    });

    testWidgets("a credential that is no document: its values", (tester) async {
      await pumpPermission(tester, id: "pbdf.pbdf.email");
      expect(find.byKey(const Key("issuance_heading")), findsOneWidget);
      expect(find.byType(DocumentIssuanceData), findsNothing);
    });

    testWidgets("who gives it, the rows and the validity", (tester) async {
      await pumpPermission(tester);

      // Who gives it as the page heading, the data under it.
      final heading = _styleOf(tester, "Je krijgt een kaartje van");
      expect(heading.fontSize, 24);
      expect(heading.fontWeight, FontWeight.w700);
      expect(
        tester.getRect(find.byType(DocumentIssuanceData)).top,
        greaterThan(
          tester.getRect(find.byKey(const Key("issuance_heading"))).bottom,
        ),
      );

      final value = _styleOf(tester, "SPECI2021");
      expect(value.fontSize, 16);
      expect(value.fontWeight, FontWeight.w700);

      // A row: the label, the value and the line between the rows.
      final first = tester.getTopLeft(find.text("Documentnummer")).dy;
      final second = tester.getTopLeft(find.text("Voornaam")).dy;
      expect(second - first, 55);

      expect(find.text("Geldig tot"), findsOneWidget);
      expect(find.text("2 augustus 2031"), findsOneWidget);
      expect(find.text("Deelbaar"), findsOneWidget);
      expect(_styleOf(tester, "2 augustus 2031").fontWeight, FontWeight.w700);
    });

    testWidgets("the age row: summary, label, chips and a toggle", (
      tester,
    ) async {
      await pumpPermission(tester);

      expect(find.text("Ouder dan 21, niet ouder dan 65"), findsOneWidget);
      await tester.tap(find.text("Toon alle leeftijden"));
      await tester.pumpAndSettle();

      expect(find.text("Ouder dan"), findsOneWidget);
      expect(find.text("✓ 12"), findsOneWidget);
      expect(find.text("– 65"), findsOneWidget);
      final chip = tester.getRect(
        find
            .ancestor(of: find.text("✓ 12"), matching: find.byType(Container))
            .first,
      );
      expect(chip.height, 30);
      expect(
        tester.getRect(find.text("✓ 21")).left -
            tester.getRect(find.text("✓ 12")).right,
        greaterThan(0),
      );
      expect(find.text("Verberg leeftijden"), findsOneWidget);
    });

    testWidgets("one button; the close button declines", (tester) async {
      await pumpPermission(tester);

      expect(find.byKey(DocumentFlowButton.primaryKey), findsOneWidget);
      expect(find.byKey(DocumentFlowButton.secondaryKey), findsNothing);
      expect(find.text("Annuleer"), findsNothing);
    });

    testWidgets("the close button is on the right of the bar", (tester) async {
      await pumpPermission(tester);

      // The round glass close button of the redesign.
      final close = tester.getRect(find.bySemanticsLabel("Sluiten"));
      expect(close.size, const Size(44, 44));
      expect(close.right, _phone.width - 16);
    });
  });
}
