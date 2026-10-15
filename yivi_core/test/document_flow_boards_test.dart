// Layout checks against the "Final (A1-K5)" design boards of the document flow
// (G1 to G9). Each test names the board it follows.
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/models/log_entry.dart" show CredentialFormat;
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/providers/feature_flag_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_instruction_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/face_verification_intro_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/mrz_reader_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/document_instruction_animation.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/face_frame_illustration.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/nfc_stage_pictures.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/nfc_stage_view.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/passport_mrz_camera_overlay.dart";
import "package:yivi_core/src/screens/session/widgets/document_issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/screens/session/widgets/session_scaffold.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/test_detection.dart";
import "package:yivi_core/src/widgets/document_flow_footer.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";
import "package:yivi_core/src/widgets/irma_avatar.dart";

import "support/pump_translated.dart";

enum _Flag { on, off }

/// Whether the animations that loop on a timer run.
enum _Ticker { stopped, running }

/// What an age attribute says about the holder.
enum _Over { yes, no }

const _phone = Size(390, 844);
const _dutch = Locale("nl", "NL");

const _textColor = Color(0xFF484747);
const _lightBlue = Color(0xFFEAF3F9);
const _blue = Color(0xFFCFE4EF);

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Locale locale = const Locale("en", "US"),
  _Flag flag = .on,
  _Ticker ticker = .stopped,
}) async {
  tester.view
    ..physicalSize = _phone
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Widget app = IrmaTheme(
    builder: (_) => MaterialApp(
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            basePath: "assets/locales",
            forcedLocale: locale,
          ),
        ),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: home,
    ),
  );
  // TestContext stops the animations that loop on a timer, so that
  // pumpAndSettle can finish.
  if (ticker == .stopped) app = TestContext(child: app);

  await pumpTranslated(
    tester,
    ProviderScope(
      overrides: [
        featureFlagProvider(
          FeatureFlag.documentFlowV2,
        ).overrideWith((ref) => Stream.value(flag == .on)),
      ],
      child: app,
    ),
  );
  // A looping animation never settles.
  ticker == .running ? await tester.pump() : await tester.pumpAndSettle();
}

Finder _primary() => find.byKey(const Key("bottom_bar_primary"));
Finder _secondary() => find.byKey(const Key("bottom_bar_secondary"));

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

/// The footers of the redesign: 56 high pills, 4 apart, 16 above, 24 under,
/// 16 on the sides.
void _expectFooterButton(WidgetTester tester, Finder button, {double? top}) {
  final rect = tester.getRect(button);
  expect(rect.height, 56);
  expect(rect.left, 16);
  expect(rect.width, _phone.width - 32);
  if (top != null) expect(rect.top, top);
}

void main() {
  group("G1 · how to hold the passport", () {
    Future<void> pumpScreen(WidgetTester tester) => _pump(
      tester,
      DocumentInstructionScreen(
        documentType: DocumentType.passport,
        onStart: () {},
        onCancel: () {},
      ),
      locale: _dutch,
    );

    testWidgets("the picture is 320 by 256, the title 24 below it", (
      tester,
    ) async {
      await pumpScreen(tester);

      final picture = tester.getRect(find.byType(DocumentInstructionAnimation));
      expect(picture.size, const Size(320, 256));
      // 16 page padding and 16 inside the tinted stage.
      expect(picture.top, IrmaAppBar.toolbarHeight + 16 + 16);
      expect(
        tester
            .getTopLeft(
              find.text("Open je paspoort op de pagina met je pasfoto"),
            )
            .dy,
        picture.bottom + 16 + 24,
      );
    });

    testWidgets("Dutch copy, heading 22 bold, the tip 14 in grey", (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text("Paspoort scannen"), findsOneWidget);
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
      expect(heading.fontSize, 22);
      expect(heading.fontWeight, FontWeight.w700);
      expect(heading.height, 30 / 22);

      final tip = _styleOf(
        tester,
        "Leg het paspoort niet direct onder een lamp, dan geeft het minder "
        "reflectie.",
      );
      expect(tip.fontSize, 14);
      expect(tip.color, _textColor);
    });

    testWidgets("the picture has a text for screen readers, the bar has no "
        "line", (tester) async {
      await pumpScreen(tester);

      expect(
        find.bySemanticsLabel(
          "Een open paspoort op de pagina met de pasfoto. De twee regels "
          "onderaan zijn gemarkeerd.",
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<IrmaAppBar>(find.byType(IrmaAppBar)).hasBorder,
        isFalse,
      );
    });

    testWidgets("Start and Annuleer are 56 high pills", (tester) async {
      await pumpScreen(tester);

      expect(find.text("Start"), findsOneWidget);
      expect(find.text("Annuleer"), findsOneWidget);
      _expectFooterButton(
        tester,
        _primary(),
        top: _phone.height - 24 - 56 - 4 - 56,
      );
      expect(tester.getRect(_secondary()).bottom, _phone.height - 24);
      expect(
        tester.getRect(_secondary()).top - tester.getRect(_primary()).bottom,
        4,
      );
    });
  });

  group("G2 · camera", () {
    Future<void> pumpScreen(WidgetTester tester, {required _Flag flag}) =>
        _pump(
          tester,
          MrzReaderScreen(
            overlayBuilder: ({required success, required child}) =>
                PassportMrzCameraOverlay(success: success, child: child),
            translationKeys: MrzReaderTranslationKeys(
              title: "passport.scan.title",
              manualEntryButton: "passport.scan.manual",
              error: "passport.scan.error",
              success: "passport.scan.success",
              successExplanation: "passport.scan.success_explanation",
            ),
            onSuccess: (_) {},
            onManualAdd: () {},
            onCancel: () {},
            mrzParser: PassportMrzParser(),
          ),
          locale: _dutch,
          flag: flag,
        );

    testWidgets("flag on: Voer handmatig in and Annuleer, 56 high", (
      tester,
    ) async {
      await pumpScreen(tester, flag: .on);

      expect(find.text("Voer handmatig in"), findsOneWidget);
      expect(find.text("Annuleer"), findsOneWidget);
      _expectFooterButton(tester, _primary());
      _expectFooterButton(tester, _secondary());
      expect(
        tester.widget<IrmaAppBar>(find.byType(IrmaAppBar)).hasBorder,
        isFalse,
      );
    });

    testWidgets("flag off: the buttons are as they were", (tester) async {
      await pumpScreen(tester, flag: .off);

      expect(find.text("Annuleren"), findsOneWidget);
      expect(tester.getSize(_primary()).height, 50);
      expect(
        tester.widget<IrmaAppBar>(find.byType(IrmaAppBar)).hasBorder,
        isTrue,
      );
    });
  });

  group("G3 G4 G6 G9 · reading the document", () {
    NfcStageScaffold stage({
      required Widget picture,
      required String title,
      required String body,
      required List<NfcStageAction> actions,
      Widget? leading = const YiviBackButton(),
    }) => NfcStageScaffold(
      appBarTitleKey: "passport.nfc.title",
      picture: picture,
      titleKey: title,
      bodyKey: body,
      textParams: const {"document": "paspoort"},
      actions: actions,
      leading: leading,
    );

    NfcStageAction cancel() => NfcStageAction.secondary(
      labelKey: "document_flow.cancel",
      onPressed: () {},
    );

    testWidgets("G3: picture area 380, phone 300, title 24 bold in grey", (
      tester,
    ) async {
      await _pump(
        tester,
        stage(
          picture: const NfcPhoneOnPassport(),
          title: "document_flow.nfc.waiting_title",
          body: "document_flow.nfc.waiting_body_passport",
          actions: [cancel()],
        ),
        locale: _dutch,
      );

      expect(find.text("Lees paspoort"), findsOneWidget);
      expect(find.text("Leg je telefoon op je paspoort"), findsOneWidget);
      expect(find.text("Je paspoort mag dicht blijven."), findsOneWidget);
      expect(find.text("Annuleer"), findsOneWidget);

      expect(
        tester.getRect(find.byKey(const Key("nfc_stage_picture"))),
        Rect.fromLTWH(0, IrmaAppBar.toolbarHeight, _phone.width, 380),
      );
      expect(
        tester.getSize(find.byType(NfcPhoneOnPassport)),
        const Size(300, 300),
      );

      final title = _styleOf(tester, "Leg je telefoon op je paspoort");
      expect(title.fontSize, 24);
      expect(title.fontWeight, FontWeight.w700);
      expect(title.height, 32 / 24);
      expect(title.color, _textColor);
      expect(
        tester.getTopLeft(find.text("Leg je telefoon op je paspoort")).dy,
        IrmaAppBar.toolbarHeight + 380,
      );
      // 10 between the title and the line under it.
      expect(
        tester.getTopLeft(find.text("Je paspoort mag dicht blijven.")).dy,
        tester.getRect(find.text("Leg je telefoon op je paspoort")).bottom + 10,
      );
      _expectFooterButton(tester, _secondary(), top: _phone.height - 24 - 56);
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

    testWidgets("G6: no back arrow, and the bar keeps its 96", (tester) async {
      await _pump(
        tester,
        stage(
          picture: const NfcDoneCheck(),
          title: "document_flow.nfc.done_title",
          body: "document_flow.nfc.done_body",
          actions: const [],
          leading: null,
        ),
        locale: _dutch,
      );

      expect(find.text("Je paspoort is gelezen"), findsOneWidget);
      expect(find.text("Je kunt je telefoon weer oppakken."), findsOneWidget);
      expect(find.byKey(const Key("irma_app_bar_leading")), findsNothing);
      expect(tester.getSize(find.byType(NfcDoneCheck)), const Size(240, 240));
      expect(tester.getSize(find.byType(DocumentFlowFooter)).height, 96);
    });

    testWidgets("G9: NFC off, 200 picture, two buttons", (tester) async {
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
        const Size(200, 200),
      );
      // 16 above, the two pills 4 apart, 24 under. The test font is wide, so
      // the longer label wraps and its pill grows past 56.
      expect(
        tester.getSize(find.byType(DocumentFlowFooter)).height,
        16 +
            tester.getSize(_primary()).height +
            4 +
            tester.getSize(_secondary()).height +
            24,
      );
      expect(
        tester.getRect(_secondary()).top - tester.getRect(_primary()).bottom,
        4,
      );
    });

    testWidgets("the picture area is the same height in every state", (
      tester,
    ) async {
      for (final picture in [
        const NfcPhoneOnPassport(),
        const NfcProgressRing(progress: 0.5, label: "x"),
        const NfcDoneCheck(),
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
          380,
        );
      }
    });
  });

  group("footer buttons", () {
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
              bottomNavigationBar: DocumentFlowFooter(
                buttons: [
                  DocumentFlowButton(
                    labelKey: "document_flow.nfc.open_settings",
                    onPressed: () {},
                  ),
                ],
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
          bottomNavigationBar: DocumentFlowFooter(
            buttons: [
              DocumentFlowButton(
                labelKey: "document_flow.cancel",
                onPressed: null,
              ),
            ],
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
        const Scaffold(body: Center(child: NfcPhoneOnPassport())),
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
        const Scaffold(body: Center(child: NfcDoneCheck())),
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
      FaceVerificationIntroScreen(
        onStart: () {},
        onCancel: () {},
        style: FaceVerificationIntroStyle.documentFlowV2,
      ),
      locale: _dutch,
    );

    testWidgets("Dutch copy, a picture of 200, one Start button", (
      tester,
    ) async {
      await pumpIntro(tester);

      expect(find.text("Gezichtsverificatie"), findsOneWidget);
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

      final picture = tester.getRect(find.byType(FaceFrameIllustration));
      expect(picture.size, const Size(200, 200));
      expect(picture.top, IrmaAppBar.toolbarHeight + 24);
      expect(tester.getTopLeft(find.text(explanation)).dy, picture.bottom + 20);

      expect(find.text("Start verificatie"), findsOneWidget);
      expect(_secondary(), findsNothing);
      _expectFooterButton(tester, _primary(), top: _phone.height - 24 - 56);
    });

    testWidgets("the tips are 12 apart, in a group", (tester) async {
      await pumpIntro(tester);

      final first = tester.getRect(
        find.text("Richt de selfie camera op je gezicht."),
      );
      final second = tester.getRect(find.text("Zorg voor voldoende licht."));
      expect(second.top - first.bottom, 12);
      // Page padding, the group's padding, the tick and the gap.
      expect(first.left, 24 + 16 + 22 + 12);
    });
  });

  group("G8 · permission for the document", () {
    final issuer = schemaless.TrustedParty(
      id: "pbdf.pbdf",
      name: "Stichting Privacy by Design",
      url: null,
      parent: null,
      verified: true,
    );

    schemaless.Attribute text(String claim, String name, String value) =>
        schemaless.Attribute(
          claimPath: [claim],
          displayName: name,
          value: schemaless.AttributeValue(
            type: schemaless.AttributeType.string,
            string: value,
          ),
        );

    schemaless.Attribute age(int years, _Over answer) => schemaless.Attribute(
      claimPath: ["over$years"],
      displayName: "Over $years",
      value: schemaless.AttributeValue(
        type: schemaless.AttributeType.string,
        string: answer.name,
      ),
    );

    schemaless.Credential credential(String id) {
      return schemaless.Credential(
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
      _Flag flag = .on,
    }) => _pump(
      tester,
      IssuancePermission(
        issuedCredentials: [credential(id)],
        onGivePermission: () {},
        onDismiss: () {},
      ),
      locale: _dutch,
      flag: flag,
    );

    testWidgets("flag on: the document gets the board's screen", (
      tester,
    ) async {
      await pumpPermission(tester);

      expect(find.byType(DocumentIssuancePermission), findsOneWidget);
      expect(find.byType(SessionScaffold), findsNothing);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        _lightBlue,
      );
    });

    testWidgets("flag off, or a credential that is no document: as before", (
      tester,
    ) async {
      await pumpPermission(tester, flag: .off);
      expect(find.byType(SessionScaffold), findsOneWidget);
      expect(find.byType(DocumentIssuancePermission), findsNothing);

      await pumpPermission(tester, id: "pbdf.pbdf.email");
      expect(find.byType(SessionScaffold), findsOneWidget);
      expect(find.byType(DocumentIssuancePermission), findsNothing);
    });

    testWidgets("the intro box, the header, the rows and the validity", (
      tester,
    ) async {
      await pumpPermission(tester);

      expect(find.text("Gegevens toevoegen"), findsWidgets);
      final intro = find.ancestor(
        of: find.text("Wil je deze gegevens aan je Yivi-app toevoegen?"),
        matching: find.byType(Container),
      );
      final box = tester.widget<Container>(intro.first);
      expect((box.decoration! as BoxDecoration).color, _blue);
      expect(
        (box.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(20),
      );
      expect(
        box.padding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

      expect(tester.getSize(find.byType(IrmaAvatar)), const Size(44, 44));
      final name = _styleOf(tester, "Paspoort");
      expect(name.fontSize, 16);
      expect(name.fontWeight, FontWeight.w700);
      expect(name.height, 22 / 16);
      expect(_styleOf(tester, "Stichting Privacy by Design").fontSize, 14);

      final value = _styleOf(tester, "SPECI2021");
      expect(value.fontSize, 16);
      expect(value.fontWeight, FontWeight.w700);

      // A row is 6 + 20 + 22 + 6 high.
      final first = tester.getTopLeft(find.text("Documentnummer")).dy;
      final second = tester.getTopLeft(find.text("Voornaam")).dy;
      expect(second - first, 6 + 20 + 22 + 6);

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

    testWidgets("the footer: the choice, then Annuleer as underlined text", (
      tester,
    ) async {
      await pumpPermission(tester);

      expect(find.text("Annuleer"), findsOneWidget);
      expect(_styleOf(tester, "Annuleer").decoration, TextDecoration.underline);
      _expectFooterButton(tester, _primary());
      _expectFooterButton(tester, _secondary(), top: _phone.height - 24 - 56);
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
