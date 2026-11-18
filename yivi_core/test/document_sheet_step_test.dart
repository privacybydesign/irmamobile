import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/providers/document_reader_providers.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";
import "package:yivi_core/src/providers/regula_face_service_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_flow.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_issuance.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_sheet_step.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/face_verification_intro_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/nfc_reading_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issue_sheet_progress.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/test_detection.dart";
import "package:yivi_core/src/widgets/sheet/glass_sheet.dart";

import "helpers/test_translation_loader.dart";
import "support/document_fakes.dart";
import "support/pump_translated.dart";

/// Adding a passport in a sheet as it works today: which screen is on top,
/// the step and the total in the progress, the bar's title, back, the face
/// check and reading again. Phase 7 moves this onto a notifier; these must
/// keep passing.
void main() {
  // The read runs inside PrivacyScreen.suspendDuring, over a method channel.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("privacy_screen"),
          (call) async => true,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel("privacy_screen"), null);
  });

  late BuildContext home;
  var backs = 0;

  /// How often the issuer asked for a face check (the flow's flag turned on).
  var faceChecks = 0;

  Future<void> pump(
    WidgetTester tester, {
    PassportIssuer? issuer,
    RegulaFaceService? face,
  }) async {
    backs = faceChecks = 0;
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpTranslated(
      tester,
      ProviderScope(
        overrides: [
          passportReaderProvider.overrideWith2(
            (_) => SucceedingPassportReader(),
          ),
          passportIssuerProvider.overrideWithValue(
            issuer ?? WaitingIssuanceIssuer(),
          ),
          regulaFaceServiceProvider.overrideWithValue(face),
          nfcDoneHoldProvider.overrideWithValue(Duration.zero),
        ],
        child: TestContext(
          child: IrmaTheme(
            builder: (_) => MaterialApp(
              localizationsDelegates: [
                FlutterI18nDelegate(
                  translationLoader: TestTranslationLoader(
                    basePath: "assets/locales",
                    forcedLocale: const Locale("en", "US"),
                  ),
                ),
                ...GlobalMaterialLocalizations.delegates,
              ],
              home: Builder(
                builder: (context) {
                  home = context;
                  return const Scaffold(body: Text("home"));
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    showGlassSheet<void>(
      context: home,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return GlassSheetPages(
            onBack: () => backs++,
            pages: [
              DocumentSheetStep(
                key: const ValueKey("document"),
                type: DocumentType.passport,
                subject: const IssueSheetSubject.none(),
                onBack: () => backs++,
              ),
            ],
          );
        },
      ),
    );
    await frames(tester);
    ProviderScope.containerOf(home).listen(
      documentFlowProvider(DocumentType.passport).select((s) => s.faceCheck),
      (before, now) {
        if (now && before != true) faceChecks++;
      },
    );
  }

  (int, int)? progress(WidgetTester tester) {
    for (final e
        in find
            .byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<(String, int, int)> &&
                  (w.key! as ValueKey<(String, int, int)>).value.$1 ==
                      "issue_sheet_progress",
            )
            .evaluate()) {
      final v = (e.widget.key! as ValueKey<(String, int, int)>).value;
      return (v.$2, v.$3);
    }
    return null;
  }

  Future<void> manualEntry(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key("bottom_bar_primary")).last);
    await frames(tester);
    await tester.enterText(
      find.byKey(const Key("document_nr_input_field")),
      "AB1234567",
    );
    await tester.enterText(
      find.byKey(const Key("passport_dob_field")),
      "1990-01-01",
    );
    await tester.enterText(
      find.byKey(const Key("passport_expiry_date_field")),
      "2030-12-31",
    );
    await frames(tester);
  }

  Future<void> toChip(WidgetTester tester) async {
    await manualEntry(tester);
    await tester.tap(find.byKey(const Key("bottom_bar_primary")).last);
    await frames(tester);
  }

  /// The read (on Android it starts by itself) and the issuer's answers.
  Future<void> readChip(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await frames(tester);
    }
  }

  testWidgets("the instruction is step 2 of 5, named after the document; "
      "back leaves the step", (tester) async {
    await pump(tester);
    expect(progress(tester), (2, 5));
    expect(find.bySemanticsLabel("Scan passport"), findsWidgets);
    await tester.tap(find.bySemanticsLabel("Go back").last);
    await frames(tester);
    expect(backs, 1);
  });

  testWidgets("without a camera, Start types it in: step 3 of 5", (
    tester,
  ) async {
    await pump(tester);
    await manualEntry(tester);
    expect(progress(tester), (3, 5));
    expect(find.byKey(const Key("document_nr_input_field")), findsOneWidget);
  });

  testWidgets("the details read: the chip, step 4 of 5, named for it", (
    tester,
  ) async {
    await pump(tester);
    await toChip(tester);
    expect(find.byType(NfcReadingScreen), findsOneWidget);
    expect(progress(tester), (4, 5));
    expect(find.bySemanticsLabel("Read passport"), findsWidgets);
  });

  testWidgets("a face check: its intro is step 5 of 6; Start, the data is "
      "fetched (step 4 of 6, today); back, the chip again", (tester) async {
    await pump(
      tester,
      issuer: WaitingIssuanceIssuer(),
      face: PassingFaceService(),
    );
    await toChip(tester);
    await readChip(tester);
    expect(find.byType(FaceVerificationIntroScreen), findsOneWidget);
    expect(faceChecks, 1);
    expect(progress(tester), (5, 6));
    expect(find.bySemanticsLabel("Face verification"), findsWidgets);

    await tester.tap(find.byKey(const Key("bottom_bar_primary")).last);
    await frames(tester);
    expect(find.byType(FaceVerificationIntroScreen), findsNothing);
    expect(find.bySemanticsLabel("Getting your data"), findsWidgets);
    expect(progress(tester), (4, 6));
  });

  testWidgets("back on the face intro: the chip again, which on Android "
      "reads again by itself and asks again", (tester) async {
    await pump(
      tester,
      issuer: WaitingIssuanceIssuer(),
      face: PassingFaceService(),
    );
    await toChip(tester);
    await readChip(tester);
    expect(find.byType(FaceVerificationIntroScreen), findsOneWidget);
    expect(faceChecks, 1);
    await tester.tap(find.bySemanticsLabel("Go back"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // On the chip for a moment.
    expect(find.byType(NfcReadingScreen), findsOneWidget);
    await readChip(tester);
    // Asked again: the intro is back, still one step more.
    expect(find.byType(FaceVerificationIntroScreen), findsOneWidget);
    expect(progress(tester), (5, 6));
  });

  testWidgets("read again: the chip on top again, the screens after it gone", (
    tester,
  ) async {
    await pump(tester);
    await toChip(tester);
    final before = tester.state(find.byType(NfcReadingScreen));
    // What the issue flow does on back from adding it.
    ProviderScope.containerOf(
      home,
    ).read(documentFlowProvider(DocumentType.passport).notifier).readAgain();
    await frames(tester);
    expect(find.byType(NfcReadingScreen), findsOneWidget);
    expect(
      identical(tester.state(find.byType(NfcReadingScreen)), before),
      isFalse,
    );
    expect(progress(tester), (4, 5));
  });

  testWidgets("system back steps back a screen, not out of the step", (
    tester,
  ) async {
    await pump(tester);
    await manualEntry(tester);
    expect(progress(tester), (3, 5));
    await tester.binding.handlePopRoute();
    await frames(tester);
    expect(progress(tester), (2, 5));
    expect(backs, 0);
  });
}

/// A fixed number of frames: the pictures animate on, so pumpAndSettle
/// would not end.
Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
