import "dart:typed_data";
import "dart:ui" as ui;

import "package:flutter/material.dart" as core;
import "package:flutter/rendering.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/session_state_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/driving_licence_mrz_manual_entry_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/passport_mrz_manual_entry_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/date_input_field.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/email/widgets/enter_email_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/sms/widgets/enter_phonenumber_screen.dart";
import "package:yivi_core/src/screens/review/store_review_feedback_dialog.dart";
import "package:yivi_core/src/screens/session/widgets/openid4vci_preauth_txcode_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/irma_divider.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";
import "package:yivi_core/src/widgets/yivi_field_group.dart";
import "package:yivi_core/src/widgets/yivi_text_field.dart";

/// A pixel read from a screenshot of the test app, at 1 logical px per pixel.
class _Screenshot {
  final ByteData _bytes;
  final int _width;

  _Screenshot(this._bytes, this._width);

  Color at(num x, num y) {
    final offset = (y.floor() * _width + x.floor()) * 4;
    return Color.fromARGB(
      _bytes.getUint8(offset + 3),
      _bytes.getUint8(offset),
      _bytes.getUint8(offset + 1),
      _bytes.getUint8(offset + 2),
    );
  }

  /// Whether [color] is anywhere in the column at [x] between [top] and [bottom].
  bool columnHas(Color color, num x, num top, num bottom) {
    for (var y = top.floor(); y < bottom.ceil(); y++) {
      if (at(x, y) == color) return true;
    }
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final theme = IrmaThemeData();
  final boundaryKey = GlobalKey();
  late IrmaPreferences prefs;

  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  setUp(() async {
    prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
  });

  Future<void> pumpField(
    WidgetTester tester,
    Widget child, {
    required bool flag,
    String locale = "en",
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await prefs.setFeatureFlag(FeatureFlag.formFieldsV2, flag);

    // FileTranslationLoader reads the locale JSON with real IO, which the test
    // framework's fake clock does not drive.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            ...overrides,
          ],
          child: IrmaTheme(
            builder: (context) => MaterialApp(
              theme: IrmaTheme.of(context).themeData,
              builder: (context, child) => LegacyMaterialBridge(child: child!),
              localizationsDelegates: [
                FlutterI18nDelegate(
                  translationLoader: FileTranslationLoader(
                    basePath: "assets/locales",
                    forcedLocale: Locale(locale),
                  ),
                ),
                ...GlobalMaterialLocalizations.delegates,
              ],
              home: RepaintBoundary(key: boundaryKey, child: child),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  Future<_Screenshot> screenshot(WidgetTester tester) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final image = await tester.runAsync(() => boundary.toImage());
    final bytes = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    return _Screenshot(bytes!, image!.width);
  }

  /// The field on the blue page background of the manual entry screens.
  Widget onPage(Widget child) {
    return Builder(
      builder: (context) => Scaffold(
        backgroundColor: IrmaTheme.of(context).backgroundTertiary,
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  Widget textField({
    String label = "Label",
    String? hint,
    TextEditingController? controller,
    FocusNode? focusNode,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return YiviTextField(
      label: label,
      hint: hint,
      legacyDecoration: const InputDecoration(hintText: "legacy hint"),
      builder: (decoration, errorBuilder) => TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        decoration: decoration,
        errorBuilder: errorBuilder,
        validator: validator,
        autovalidateMode: AutovalidateMode.always,
      ),
    );
  }

  Rect decoratorRect(WidgetTester tester) =>
      tester.getRect(find.byType(InputDecorator).first);

  InputDecoration decorationOf(WidgetTester tester) => tester
      .widget<InputDecorator>(find.byType(InputDecorator).first)
      .decoration;

  Color labelColor(WidgetTester tester, String label) {
    final style = tester.widget<AnimatedDefaultTextStyle>(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .first,
    );
    return style.style.color!;
  }

  group("single field", () {
    testWidgets("is white with the label inside and a grey 2px line", (
      tester,
    ) async {
      await pumpField(tester, onPage(textField(hint: "Hint")), flag: true);
      final shot = await screenshot(tester);
      final rect = decoratorRect(tester);

      expect(shot.at(rect.left + 20, rect.top + 4), theme.light);
      expect(shot.at(rect.center.dx, rect.bottom - 1), theme.neutralDark);
      expect(shot.at(rect.center.dx, rect.bottom - 2), theme.neutralDark);
      expect(shot.at(rect.center.dx, rect.bottom - 3), theme.light);

      // The label is 12 px (Material scales it to 75% of the 16 px it is declared
      // at) and sits inside the field, above the value.
      final label = tester.getRect(find.text("Label"));
      expect(label.height, 12);
      expect(label.top, greaterThanOrEqualTo(rect.top));
      expect(label.bottom, lessThan(rect.bottom));
      expect(labelColor(tester, "Label"), theme.neutralExtraDark);

      final hint = tester.widget<Text>(find.text("Hint"));
      expect(hint.style?.color, theme.neutralDark);
      expect(hint.style?.fontSize, 16);
    });

    testWidgets("has 8 px radius on the top corners only", (tester) async {
      await pumpField(tester, onPage(textField()), flag: true);
      final shot = await screenshot(tester);
      final rect = decoratorRect(tester);

      expect(
        shot.at(rect.left + 0.5, rect.top + 0.5),
        theme.backgroundTertiary,
      );
      expect(shot.at(rect.right - 1, rect.top + 0.5), theme.backgroundTertiary);
      expect(shot.at(rect.left + 0.5, rect.bottom - 1.5), theme.neutralDark);
      expect(shot.at(rect.left + 12, rect.top + 0.5), theme.light);
    });

    testWidgets("turns blue when focused", (tester) async {
      await pumpField(tester, onPage(textField()), flag: true);

      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      final shot = await screenshot(tester);
      final rect = decoratorRect(tester);

      expect(shot.at(rect.left + 20, rect.top + 4), theme.fieldFocusedSurface);
      expect(shot.at(rect.center.dx, rect.bottom - 1), theme.link);
      expect(labelColor(tester, "Label"), theme.link);
    });

    testWidgets("shows a red line, a red label and the message with an icon", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(textField(validator: (_) => "Enter a label")),
        flag: true,
      );
      final shot = await screenshot(tester);
      final rect = decoratorRect(tester);
      final message = tester.getRect(find.text("Enter a label"));

      // The red line is above the message, which is part of the decorator.
      expect(
        shot.columnHas(theme.error, rect.center.dx, rect.top, message.top),
        isTrue,
      );
      expect(labelColor(tester, "Label"), theme.error);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(
        tester.getRect(find.byIcon(Icons.error_outline)).right,
        lessThan(message.left),
      );
    });

    testWidgets("is greyed out when disabled", (tester) async {
      await pumpField(tester, onPage(textField(enabled: false)), flag: true);
      final shot = await screenshot(tester);
      final rect = decoratorRect(tester);

      expect(shot.at(rect.left + 20, rect.top + 4), theme.fieldDisabledSurface);
      expect(shot.at(rect.center.dx, rect.bottom - 1), theme.neutralLight);
    });

    testWidgets("keeps the decoration it was given with the flag off", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(textField(validator: (_) => "Enter a label")),
        flag: false,
      );
      final decoration = decorationOf(tester);

      expect(decoration.hintText, "legacy hint");
      expect(decoration.labelText, isNull);
      expect(decoration.filled, isNot(true));
      expect(find.text("Enter a label"), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets("is not rebuilt when the flag value arrives", (tester) async {
      final controller = TextEditingController(text: "typed");
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await pumpField(
        tester,
        onPage(textField(controller: controller, focusNode: focusNode)),
        flag: false,
      );
      focusNode.requestFocus();
      await tester.pumpAndSettle();
      final before = tester.state(find.byType(TextFormField));

      await prefs.setFeatureFlag(FeatureFlag.formFieldsV2, true);
      await tester.pumpAndSettle();

      expect(decorationOf(tester).labelText, "Label");
      expect(tester.state(find.byType(TextFormField)), same(before));
      expect(focusNode.hasFocus, isTrue);
      expect(controller.text, "typed");
    });
  });

  group("field group", () {
    Widget group({required Key first, required Key second}) {
      return YiviFieldGroup(
        children: [
          YiviTextField(
            label: "First",
            legacyDecoration: const InputDecoration(),
            builder: (decoration, errorBuilder) => TextFormField(
              key: first,
              decoration: decoration,
              errorBuilder: errorBuilder,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => value == "bad" ? "First is bad" : null,
            ),
          ),
          YiviTextField(
            label: "Second",
            legacyDecoration: const InputDecoration(),
            builder: (decoration, errorBuilder) => TextFormField(
              key: second,
              decoration: decoration,
              errorBuilder: errorBuilder,
            ),
          ),
        ],
      );
    }

    const first = Key("first");
    const second = Key("second");

    testWidgets("is one white card with dividers between the rows", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(group(first: first, second: second)),
        flag: true,
      );
      final shot = await screenshot(tester);
      final firstRow = tester.getRect(find.byType(InputDecorator).first);
      final secondRow = tester.getRect(find.byType(InputDecorator).last);

      expect(find.byType(IrmaDivider), findsOneWidget);
      expect(shot.at(firstRow.center.dx, firstRow.center.dy), theme.light);
      expect(shot.at(secondRow.center.dx, secondRow.center.dy), theme.light);
      expect(
        shot.at(firstRow.center.dx, firstRow.bottom + 0.5),
        theme.neutralExtraLight,
      );

      // 12 px radius, and a soft shadow around the card.
      final card = tester
          .widgetList<Container>(find.byType(Container))
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((decoration) => decoration.boxShadow != null);
      expect(card.borderRadius, BorderRadius.circular(12));
      expect(card.color, theme.light);
      expect(card.border, isNull);
      expect(
        shot.at(firstRow.left + 0.5, firstRow.top + 0.5),
        theme.backgroundTertiary,
      );
    });

    testWidgets("lights up the active row with a blue label and line", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(group(first: first, second: second)),
        flag: true,
      );

      await tester.tap(find.byKey(second));
      await tester.pumpAndSettle();
      final shot = await screenshot(tester);
      final firstRow = tester.getRect(find.byType(InputDecorator).first);
      final secondRow = tester.getRect(find.byType(InputDecorator).last);

      expect(
        shot.at(secondRow.center.dx, secondRow.top + 4),
        theme.surfaceSecondary,
      );
      expect(shot.at(secondRow.center.dx, secondRow.bottom - 1), theme.link);
      expect(shot.at(secondRow.center.dx, secondRow.bottom - 2), theme.link);
      expect(
        shot.at(secondRow.center.dx, secondRow.bottom - 3),
        theme.surfaceSecondary,
      );
      expect(labelColor(tester, "Second"), theme.link);

      expect(shot.at(firstRow.center.dx, firstRow.top + 4), theme.light);
      expect(
        shot.columnHas(
          theme.link,
          firstRow.center.dx,
          firstRow.top,
          firstRow.bottom,
        ),
        isFalse,
      );
    });

    testWidgets("tints an invalid row red, with no coloured left border", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(group(first: first, second: second)),
        flag: true,
      );

      await tester.enterText(find.byKey(first), "bad");
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(second));
      await tester.pumpAndSettle();
      final shot = await screenshot(tester);
      final row = tester.getRect(find.byType(InputDecorator).first);

      expect(shot.at(row.center.dx, row.top + 4), theme.errorSurface);
      expect(
        shot.columnHas(
          theme.error,
          row.center.dx,
          row.top,
          tester.getRect(find.text("First is bad")).top,
        ),
        isTrue,
      );
      expect(labelColor(tester, "First"), theme.error);
      expect(find.text("First is bad"), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // The row is tinted up to the card's edge, and no side is a coloured line.
      expect(shot.at(row.left + 0.5, row.top + 28), theme.errorSurface);
      expect(shot.at(row.left + 1.5, row.top + 28), theme.errorSurface);
    });

    testWidgets("is a plain stack with a gap with the flag off", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(
          const YiviFieldGroup(
            children: [
              SizedBox(key: first, height: 40),
              SizedBox(key: second, height: 40),
            ],
          ),
        ),
        flag: false,
      );

      expect(find.byType(IrmaDivider), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(second)).dy -
            tester.getBottomLeft(find.byKey(first)).dy,
        theme.mediumSpacing,
      );
    });
  });

  group("date field", () {
    late TextEditingController controller;

    setUp(() => controller = TextEditingController());
    tearDown(() => controller.dispose());

    Widget dateField() {
      return onPage(
        Form(
          child: DateInputField(
            controller: controller,
            labelText: "Date of birth",
            requiredText: "Date of birth is required",
            dateInvalidText: "Date is invalid",
          ),
        ),
      );
    }

    testWidgets("is typed as DD-MM-YYYY with the flag on", (tester) async {
      await pumpField(tester, dateField(), flag: true);

      expect(find.text("DD-MM-YYYY"), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), "31122025");
      await tester.pumpAndSettle();
      expect(controller.text, "31-12-2025");
      expect(find.text("Date is invalid"), findsNothing);

      await tester.enterText(find.byType(TextFormField), "31132025");
      await tester.pumpAndSettle();
      expect(controller.text, "31-13-2025");
      expect(find.text("Date is invalid"), findsOneWidget);
    });

    for (final (locale, placeholder) in [
      ("nl", "DD-MM-JJJJ"),
      ("de", "TT-MM-JJJJ"),
    ]) {
      testWidgets("shows $placeholder in $locale", (tester) async {
        await pumpField(tester, dateField(), flag: true, locale: locale);

        expect(find.text(placeholder), findsOneWidget);
      });
    }

    testWidgets("has a 44 px calendar button that fills the field", (
      tester,
    ) async {
      await pumpField(tester, dateField(), flag: true);

      expect(tester.getSize(find.byType(IconButton)), const Size(44, 44));
      expect(find.byTooltip("Choose date"), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();

      final year = DateTime.now().year - 25;
      expect(controller.text, "01-01-$year");
    });

    testWidgets("is typed as YYYY-MM-DD with the flag off", (tester) async {
      await pumpField(tester, dateField(), flag: false);

      expect(find.text("YYYY-MM-DD"), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), "20251231");
      await tester.pumpAndSettle();
      expect(controller.text, "2025-12-31");
      expect(find.text("Date is invalid"), findsNothing);

      expect(tester.getSize(find.byType(IconButton)), const Size(48, 48));
      expect(find.byTooltip("Choose date"), findsNothing);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();

      final year = DateTime.now().year - 25;
      expect(controller.text, "$year-01-01");
    });
  });

  group("manual entry", () {
    PassportMrzManualEntryScreen passportScreen(
      void Function(PassportMrzManualEntryData) onContinue,
    ) {
      return PassportMrzManualEntryScreen(
        onContinue: onContinue,
        onCancel: () {},
        translationKeys: PassportMrzManualEntryTranslationKeys(
          title: "passport.manual.title",
          explanation: "passport.manual.explanation",
          dateOfBirth: "passport.manual.fields.date_of_birth",
          dateOfBirthRequired: "passport.manual.fields.date_of_birth_required",
          dateOfExpiry: "passport.manual.fields.date_of_expiry",
          dateOfExpiryRequired:
              "passport.manual.fields.date_of_expiry_required",
          documentNumber: "passport.manual.fields.document_nr",
          documentNumberRequired: "passport.manual.fields.document_nr_required",
          documentNumberInvalid: "passport.manual.fields.document_nr_invalid",
          dateInvalid: "passport.manual.fields.date_invalid",
        ),
      );
    }

    for (final (flag, birth, expiry) in [
      (true, "01021990", "03042030"),
      (false, "19900201", "20300403"),
    ]) {
      testWidgets("passes the typed dates on with the flag $flag", (
        tester,
      ) async {
        PassportMrzManualEntryData? entered;
        await pumpField(
          tester,
          passportScreen((data) => entered = data),
          flag: flag,
        );

        await tester.enterText(
          find.byKey(const Key("document_nr_input_field")),
          "AB1234567",
        );
        await tester.enterText(
          find.byKey(const Key("passport_dob_field")),
          birth,
        );
        await tester.enterText(
          find.byKey(const Key("passport_expiry_date_field")),
          expiry,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text("Continue"));
        await tester.pumpAndSettle();

        expect(entered?.documentNr, "AB1234567");
        expect(entered?.dateOfBirth, DateTime(1990, 2, 1));
        expect(entered?.expiryDate, DateTime(2030, 4, 3));
      });
    }

    testWidgets("puts the passport fields in one card with the flag on", (
      tester,
    ) async {
      await pumpField(tester, passportScreen((_) {}), flag: true);

      expect(find.byType(IrmaDivider), findsNWidgets(2));
      expect(decorationOf(tester).labelText, "Document number");
      expect(find.text("Date of birth"), findsOneWidget);
      expect(find.text("Date of expiry"), findsOneWidget);
    });

    testWidgets("keeps the passport fields apart with the flag off", (
      tester,
    ) async {
      await pumpField(tester, passportScreen((_) {}), flag: false);

      expect(find.byType(IrmaDivider), findsNothing);
      expect(decorationOf(tester).labelText, isNull);
      expect(decorationOf(tester).label, isA<Text>());
    });

    testWidgets("puts the driving licence field in a card with the flag on", (
      tester,
    ) async {
      await pumpField(
        tester,
        DrivingLicenceMrzManualEntryScreen(onContinue: (_) {}, onCancel: () {}),
        flag: true,
      );

      expect(find.byType(IrmaDivider), findsNothing);
      expect(decorationOf(tester).labelText, "Machine readable zone (MRZ)");
      expect(decorationOf(tester).filled, isTrue);
    });

    testWidgets("shows an invalid document number with an icon", (
      tester,
    ) async {
      await pumpField(tester, passportScreen((_) {}), flag: true);

      await tester.enterText(
        find.byKey(const Key("document_nr_input_field")),
        "AB1",
      );
      await tester.pumpAndSettle();

      expect(find.text("Document number is invalid"), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group("feedback dialog", () {
    Future<void> openDialog(WidgetTester tester, {required bool flag}) async {
      await pumpField(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showStoreReviewFeedbackDialog(context),
                child: const Text("open"),
              ),
            ),
          ),
        ),
        flag: flag,
      );
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
    }

    // The label that keeps the field named once its hint is gone. With the flag
    // on the field has a label of its own.
    bool hasFeedbackSemantics(Widget widget) =>
        widget is Semantics && widget.properties.label == "Your feedback";

    InputDecoration dialogDecoration(WidgetTester tester) {
      return tester
          .widget<InputDecorator>(
            find.descendant(
              of: find.byKey(const Key("review_feedback_input")),
              matching: find.byType(InputDecorator),
            ),
          )
          .decoration;
    }

    testWidgets("has its label inside the field with the flag on", (
      tester,
    ) async {
      await openDialog(tester, flag: true);

      expect(dialogDecoration(tester).labelText, "Your feedback");
      expect(dialogDecoration(tester).hint, isNull);
      expect(dialogDecoration(tester).filled, isTrue);
      expect(find.byWidgetPredicate(hasFeedbackSemantics), findsNothing);
    });

    testWidgets("shows its hint with the flag off", (tester) async {
      await openDialog(tester, flag: false);

      expect(dialogDecoration(tester).labelText, isNull);
      expect(dialogDecoration(tester).hint, isA<Text>());
      expect(dialogDecoration(tester).filled, isNot(true));
      expect(find.byWidgetPredicate(hasFeedbackSemantics), findsOneWidget);
    });
  });

  group("transaction code screen", () {
    final issuer = TrustedParty(
      id: "issuer",
      name: "Issuer",
      url: null,
      parent: null,
      verified: false,
    );

    Widget txCodeScreen() {
      return OpenID4VCIPreAuthTxCodeScreen(
        sessionId: 1,
        issuedCredentials: [
          CredentialDescriptor(
            credentialId: "credential",
            name: "Credential",
            issuer: issuer,
            category: null,
            attributes: const [],
            issueURL: null,
          ),
        ],
        transactionCodeParameters:
            PreAuthorizationCodeTransactionCodeParameters(inputMode: "text"),
        onSubmit: (_) {},
        onDismiss: () {},
      );
    }

    Override session({int? remainingAttempts}) {
      return sessionStateProvider(1).overrideWith(
        (ref) => Stream.value(
          SessionState(
            id: 1,
            protocol: "openid4vci",
            type: SessionType.issuance,
            status: SessionStatus.requestPreAuthorizedCode,
            requestor: issuer,
            continueOnSecondDevice: false,
            remainingTxCodeAttempts: remainingAttempts,
          ),
        ),
      );
    }

    final codeField = find.byKey(const Key("openid4vci_tx_code_input_field"));

    testWidgets("shows the wrong code error in the field with the flag on", (
      tester,
    ) async {
      await pumpField(
        tester,
        txCodeScreen(),
        flag: true,
        overrides: [session(remainingAttempts: 2)],
      );

      expect(decorationOf(tester).labelText, "Transaction code");
      expect(
        find.text("Incorrect code. 2 attempts remaining."),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(tester.widget<TextField>(codeField).textAlign, TextAlign.start);
      expect(labelColor(tester, "Transaction code"), theme.error);
    });

    testWidgets("shows no error before a wrong code with the flag on", (
      tester,
    ) async {
      await pumpField(
        tester,
        txCodeScreen(),
        flag: true,
        overrides: [session()],
      );

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(labelColor(tester, "Transaction code"), isNot(theme.error));
    });

    testWidgets(
      "shows the wrong code error below the field with the flag off",
      (tester) async {
        await pumpField(
          tester,
          txCodeScreen(),
          flag: false,
          overrides: [session(remainingAttempts: 2)],
        );

        expect(decorationOf(tester).labelText, isNull);
        expect(
          find.text("Incorrect code. 2 attempts remaining."),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.error_outline), findsNothing);
        expect(tester.widget<TextField>(codeField).textAlign, TextAlign.center);
        expect(
          tester
              .widget<Text>(find.text("Incorrect code. 2 attempts remaining."))
              .style
              ?.color,
          theme.error,
        );
      },
    );
  });

  group("e-mail screen", () {
    testWidgets("has its label inside the field with the flag on", (
      tester,
    ) async {
      await pumpField(tester, const EnterEmailScreen(), flag: true);

      final decoration = decorationOf(tester);
      expect(decoration.labelText, "Email address");
      expect(decoration.hintText, "Enter your email address...");
      expect(decoration.filled, isTrue);
    });

    testWidgets("shows only its hint with the flag off", (tester) async {
      await pumpField(tester, const EnterEmailScreen(), flag: false);

      final decoration = decorationOf(tester);
      expect(decoration.labelText, isNull);
      expect(decoration.hint, isNotNull);
      expect(decoration.filled, isNot(true));
    });
  });

  group("phone number screen", () {
    core.InputDecoration phoneDecoration(WidgetTester tester) {
      return tester
          .widget<core.InputDecorator>(find.byType(core.InputDecorator).first)
          .decoration;
    }

    testWidgets("is white with the label inside with the flag on", (
      tester,
    ) async {
      await pumpField(tester, const EnterPhoneScreen(), flag: true);

      final decoration = phoneDecoration(tester);
      expect(decoration.labelText, "Phone number");
      expect(decoration.hintText, "Enter your phone number...");
      expect(decoration.filled, isTrue);

      // The screen focuses the field when it opens.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final shot = await screenshot(tester);
      final rect = tester.getRect(find.byType(core.InputDecorator).first);
      expect(shot.at(rect.center.dx, rect.top + 4), theme.light);
      expect(shot.at(rect.center.dx, rect.bottom - 1), theme.neutralDark);
    });

    testWidgets("turns blue when focused", (tester) async {
      await pumpField(tester, const EnterPhoneScreen(), flag: true);

      await tester.tap(find.byKey(const Key("phone_number_input_field")));
      await tester.pumpAndSettle();
      final shot = await screenshot(tester);
      final rect = tester.getRect(find.byType(core.InputDecorator).first);

      expect(shot.at(rect.center.dx, rect.top + 4), theme.fieldFocusedSurface);
      expect(shot.at(rect.center.dx, rect.bottom - 1), theme.link);
    });

    testWidgets("shows only its hint with the flag off", (tester) async {
      await pumpField(tester, const EnterPhoneScreen(), flag: false);

      final decoration = phoneDecoration(tester);
      expect(decoration.labelText, isNull);
      expect(decoration.hint, isNotNull);
      expect(decoration.filled, isNot(true));
    });
  });
}
