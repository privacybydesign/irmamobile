import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/routing.dart";
import "package:yivi_core/src/models/mrz.dart";
import "package:yivi_core/src/providers/document_reader_providers.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";
import "package:yivi_core/src/providers/regula_face_service_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_flow.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_issuance.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_sheet_step.dart";
import "package:yivi_core/src/screens/session/issuance/issue_sheet_progress.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/test_detection.dart";
import "package:yivi_core/src/widgets/sheet/sheet.dart";

import "../helpers/test_translation_loader.dart";
import "document_fakes.dart";
import "pump_translated.dart";

/// A passport for [DocumentSheetHarness.toChipDirect].
final testPassportMrz = ScannedPassportMrz(
  documentNumber: "AB1234567",
  countryCode: "NLD",
  dateOfBirth: DateTime(1990, 1, 1),
  dateOfExpiry: DateTime(2030, 12, 31),
);

/// Adding a document in a glass sheet, as the Add data sheet shows it:
/// [DocumentSheetStep] on [SheetPages], over a home page, with fakes
/// for the reader, the issuer and the face check.
class DocumentSheetHarness {
  late BuildContext home;

  /// The app's router: home at `/`, and `/error` showing its message.
  late GoRouter router;

  /// How many routes the router shows: a push adds one, a replacement not.
  int get depth => router.routerDelegate.currentConfiguration.matches.length;

  /// Back from the instruction (to the details).
  var backs = 0;

  ProviderContainer get container => ProviderScope.containerOf(home);

  DocumentFlow flow(DocumentType type) =>
      container.read(documentFlowProvider(type).notifier);

  /// The read runs inside PrivacyScreen.suspendDuring, over a method channel.
  static void mockPrivacyScreen() {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel("privacy_screen"),
            (call) async => true,
          );
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel("privacy_screen"),
            null,
          );
    });
  }

  Future<void> pump(
    WidgetTester tester, {
    DocumentType type = DocumentType.passport,
    PassportIssuer? issuer,
    RegulaFaceService? face,
    DocumentReader<PassportData> Function()? reader,
    Size size = const Size(390, 844),
    List<Override> overrides = const [],
  }) async {
    backs = 0;
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    router = GoRouter(
      routes: [
        GoRoute(
          path: "/",
          builder: (context, _) {
            home = context;
            return const Scaffold(body: Text("home"));
          },
        ),
        GoRoute(
          path: "/error",
          builder: (_, state) => Scaffold(body: Text("error: ${state.extra}")),
        ),
      ],
    );
    await pumpTranslated(
      tester,
      ProviderScope(
        overrides: [
          passportReaderProvider.overrideWith2(
            (_) => reader?.call() ?? SucceedingPassportReader(),
          ),
          passportIssuerProvider.overrideWithValue(
            issuer ?? WaitingIssuanceIssuer(),
          ),
          regulaFaceServiceProvider.overrideWithValue(face),
          nfcDoneHoldProvider.overrideWithValue(Duration.zero),
          routerProvider.overrideWithValue(router),
          ...overrides,
        ],
        // The pictures stand still, and the camera shows its fallback.
        child: TestContext(
          child: IrmaTheme(
            builder: (_) => MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: [
                FlutterI18nDelegate(
                  translationLoader: TestTranslationLoader(
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
    showSheet<void>(
      context: home,
      builder: (_) => SheetPages(
        onBack: () => backs++,
        pages: [
          DocumentSheetStep(
            key: const ValueKey("document"),
            type: type,
            subject: const IssueSheetSubject.none(),
            onBack: () => backs++,
          ),
        ],
      ),
    );
    await frames(tester);
  }

  /// The step and total in the sheet's progress.
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

  /// Start on the instruction, without a camera: typing it in.
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

  /// The passport typed in and Continue: the chip.
  Future<void> toChip(WidgetTester tester) async {
    await manualEntry(tester);
    await tester.tap(find.byKey(const Key("bottom_bar_primary")).last);
    await frames(tester);
  }

  /// Straight to the chip of [mrz], as a read from the camera.
  Future<void> toChipDirect(WidgetTester tester, ScannedMrz mrz) async {
    flow(mrz.documentType).read(mrz);
    await frames(tester);
  }

  /// The read (on Android it starts by itself) and the issuer's answers.
  Future<void> readChip(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await frames(tester);
    }
  }
}

/// A fixed number of frames: the pictures animate on, so pumpAndSettle
/// would not end.
Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
