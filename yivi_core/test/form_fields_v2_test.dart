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
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";
import "package:yivi_core/src/widgets/yivi_field_group.dart";
import "package:yivi_core/src/widgets/yivi_text_field.dart";

/// Which form fields a test runs with: V2 is `FeatureFlag.formFieldsV2` on.
enum _Fields { v2, legacy }

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
    required _Fields fields,
    String locale = "en",
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await prefs.setFeatureFlag(FeatureFlag.formFieldsV2, fields == _Fields.v2);

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
    String? Function(String?)? validator,
  }) {
    return YiviTextField(
      label: label,
      hint: hint,
      legacyDecoration: const InputDecoration(hintText: "legacy hint"),
      builder: (decoration, errorBuilder, style) => TextFormField(
        controller: controller,
        focusNode: focusNode,
        style: style,
        decoration: decoration,
        errorBuilder: errorBuilder,
        validator: validator,
        autovalidateMode: AutovalidateMode.always,
      ),
    );
  }

  /// The background the screen sets on its scaffold, if any.
  Color? pageColor(WidgetTester tester) =>
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;

  Rect decoratorRect(WidgetTester tester) =>
      tester.getRect(find.byType(InputDecorator).first);

  InputDecoration decorationOf(WidgetTester tester) => tester
      .widget<InputDecorator>(find.byType(InputDecorator).first)
      .decoration;

  TextStyle labelStyle(WidgetTester tester, String label) {
    return tester
        .widget<AnimatedDefaultTextStyle>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(AnimatedDefaultTextStyle),
              )
              .first,
        )
        .style;
  }

  Color labelColor(WidgetTester tester, String label) =>
      labelStyle(tester, label).color!;

  Rect valueRect(WidgetTester tester, [int index = 0]) =>
      tester.getRect(find.byType(EditableText).at(index));

  group("single field", () {
    testWidgets("is white with the label inside and a grey 2px line", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(textField(hint: "Hint")),
        fields: _Fields.v2,
      );
      final shot = await screenshot(tester);
      final rect = decoratorRect(tester);

      expect(shot.at(rect.left + 20, rect.top + 4), theme.light);
      expect(shot.at(rect.center.dx, rect.bottom - 1), theme.neutralDark);
      expect(shot.at(rect.center.dx, rect.bottom - 2), theme.neutralDark);
      expect(shot.at(rect.center.dx, rect.bottom - 3), theme.light);

      // Board H1: 8 px above the 16 px label line, then the 26 px value line,
      // 8 px above the bottom, with the line in it. The text is 14 px from the
      // sides.
      final label = tester.getRect(find.text("Label"));
      final value = valueRect(tester);
      expect(rect.height, 58);
      expect(label.left - rect.left, 14);
      expect(label.top - rect.top, 8);
      expect(label.height, 12);
      expect(value.left - rect.left, 14);
      expect(value.top - rect.top, 24);
      expect(value.height, 26);
      expect(labelColor(tester, "Label"), theme.neutralExtraDark);
      expect(labelStyle(tester, "Label").fontWeight, FontWeight.w600);

      final hint = tester.widget<Text>(find.text("Hint"));
      expect(hint.style?.color, theme.neutralDark);
      expect(hint.style?.fontSize, 16);
    });

    testWidgets("casts a shadow below the field, not behind its message", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(textField(validator: (_) => "Enter a label")),
        fields: _Fields.v2,
      );
      final shot = await screenshot(tester);
      final rect = decoratorRect(tester);
      final fieldBottom = rect.top + 58;
      final message = tester.getRect(find.text("Enter a label"));

      expect(shot.at(rect.center.dx, fieldBottom - 1), theme.error);
      final shadow = shot.at(rect.center.dx, fieldBottom);
      expect(shadow, isNot(theme.backgroundTertiary));
      expect(shadow, isNot(theme.light));
      expect(
        shot.at(rect.center.dx, message.top - 2),
        theme.backgroundTertiary,
      );
    });

    testWidgets("has 8 px radius on the top corners only", (tester) async {
      await pumpField(tester, onPage(textField()), fields: _Fields.v2);
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

    testWidgets("stays white when focused, with a blue line and label", (
      tester,
    ) async {
      await pumpField(tester, onPage(textField()), fields: _Fields.v2);

      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      final shot = await screenshot(tester);
      final rect = decoratorRect(tester);

      expect(shot.at(rect.left + 20, rect.top + 4), theme.light);
      expect(shot.at(rect.center.dx, rect.bottom - 1), theme.link);
      expect(labelColor(tester, "Label"), theme.link);
    });

    testWidgets("shows a red line, a red label and the message with an icon", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(textField(validator: (_) => "Enter a label")),
        fields: _Fields.v2,
      );
      final shot = await screenshot(tester);
      final rect = decoratorRect(tester);
      final message = tester.getRect(find.text("Enter a label"));
      final icon = tester.getRect(find.byIcon(Icons.error));

      // The red line closes the field, and the message is 4 px below it, from
      // the edge of the field and not from its text.
      expect(shot.at(rect.center.dx, rect.top + 57), theme.error);
      expect(shot.at(rect.center.dx, rect.top + 56), theme.error);
      expect(shot.at(rect.center.dx, rect.top + 55), theme.light);
      expect(icon.left, rect.left);
      expect(icon.size, const Size(14, 14));
      expect(icon.right, lessThan(message.left));
      expect(message.top - rect.top, 62);
      expect(message.height, 18);

      expect(labelColor(tester, "Label"), theme.error);
      final style = tester.widget<Text>(find.text("Enter a label")).style;
      expect(style?.fontSize, 13);
      expect(style?.fontWeight, FontWeight.w600);
      expect(style?.color, theme.error);
    });

    testWidgets("is greyed out when disabled", (tester) async {
      await pumpField(
        tester,
        onPage(
          YiviTextField(
            label: "Label",
            legacyDecoration: const InputDecoration(),
            builder: (decoration, _, style) =>
                TextField(enabled: false, style: style, decoration: decoration),
          ),
        ),
        fields: _Fields.v2,
      );
      final shot = await screenshot(tester);
      final rect = decoratorRect(tester);

      expect(shot.at(rect.left + 20, rect.top + 4), theme.fieldDisabledSurface);
      expect(shot.at(rect.center.dx, rect.bottom - 1), theme.neutralLight);
      expect(shot.at(rect.center.dx, rect.bottom), theme.backgroundTertiary);
    });

    testWidgets("keeps the decoration it was given with the flag off", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(textField(validator: (_) => "Enter a label")),
        fields: _Fields.legacy,
      );
      final decoration = decorationOf(tester);

      expect(decoration.hintText, "legacy hint");
      expect(decoration.labelText, isNull);
      expect(decoration.filled, isNot(true));
      expect(find.text("Enter a label"), findsOneWidget);
      expect(find.byIcon(Icons.error), findsNothing);
    });

    testWidgets("is not rebuilt when the flag value arrives", (tester) async {
      final controller = TextEditingController(text: "typed");
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await pumpField(
        tester,
        onPage(textField(controller: controller, focusNode: focusNode)),
        fields: _Fields.legacy,
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
            builder: (decoration, errorBuilder, style) => TextFormField(
              key: first,
              style: style,
              decoration: decoration,
              errorBuilder: errorBuilder,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => value == "bad" ? "First is bad" : null,
            ),
          ),
          YiviTextField(
            label: "Second",
            legacyDecoration: const InputDecoration(),
            builder: (decoration, errorBuilder, style) => TextFormField(
              key: second,
              style: style,
              decoration: decoration,
              errorBuilder: errorBuilder,
            ),
          ),
        ],
      );
    }

    const first = Key("first");
    const second = Key("second");

    Rect rowRect(WidgetTester tester, int index) =>
        tester.getRect(find.byType(YiviTextField).at(index));

    testWidgets("is one white card with a divider between the rows", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(group(first: first, second: second)),
        fields: _Fields.v2,
      );
      final shot = await screenshot(tester);
      final firstRow = rowRect(tester, 0);
      final secondRow = rowRect(tester, 1);

      // Board H2: a row is 71 px with its 1 px divider, and the last row is
      // 70 px without one.
      expect(firstRow.height, 71);
      expect(secondRow.height, 70);
      expect(shot.at(firstRow.center.dx, firstRow.center.dy), theme.light);
      expect(shot.at(secondRow.center.dx, secondRow.center.dy), theme.light);
      expect(
        shot.at(firstRow.center.dx, firstRow.bottom - 1),
        theme.neutralExtraLight,
      );
      expect(shot.at(firstRow.center.dx, firstRow.bottom - 2), theme.light);
      expect(shot.at(secondRow.center.dx, secondRow.bottom - 1), theme.light);

      // 12 px radius, and a soft shadow around the card.
      final card = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
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

    testWidgets("lays a row out as the board does", (tester) async {
      await pumpField(
        tester,
        onPage(group(first: first, second: second)),
        fields: _Fields.v2,
      );
      final row = rowRect(tester, 0);
      final label = tester.getRect(find.text("First"));
      final value = valueRect(tester);

      // 16 px from the sides, a 17 px value on a 26 px line, 13 px label.
      expect(label.left - row.left, 16);
      expect(value.left - row.left, 16);
      expect(value.top - row.top, 32);
      expect(value.height, 26);
      expect(labelStyle(tester, "First").fontWeight, FontWeight.w600);
      final style = tester
          .widget<EditableText>(find.byType(EditableText).first)
          .style;
      expect(style.fontSize, 17);
      expect(style.letterSpacing, 0);
    });

    testWidgets("marks the active row with a blue label and line only", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(group(first: first, second: second)),
        fields: _Fields.v2,
      );

      await tester.tap(find.byKey(first));
      await tester.pumpAndSettle();
      var shot = await screenshot(tester);
      final firstRow = rowRect(tester, 0);
      final secondRow = rowRect(tester, 1);

      // The line is 2 px and takes the place of the divider. The row is as
      // high as before, and keeps the white of the card.
      expect(firstRow.height, 71);
      expect(shot.at(firstRow.center.dx, firstRow.top + 4), theme.light);
      expect(shot.at(firstRow.center.dx, firstRow.bottom - 1), theme.link);
      expect(shot.at(firstRow.center.dx, firstRow.bottom - 2), theme.link);
      expect(shot.at(firstRow.center.dx, firstRow.bottom - 3), theme.light);
      expect(labelColor(tester, "First"), theme.link);
      expect(labelColor(tester, "Second"), theme.neutralExtraDark);
      expect(
        shot.columnHas(
          theme.link,
          secondRow.center.dx,
          secondRow.top,
          secondRow.bottom,
        ),
        isFalse,
      );

      await tester.tap(find.byKey(second));
      await tester.pumpAndSettle();
      shot = await screenshot(tester);

      expect(secondRow.height, 70);
      expect(shot.at(secondRow.center.dx, secondRow.top + 4), theme.light);
      expect(shot.at(secondRow.center.dx, secondRow.bottom - 1), theme.link);
      expect(shot.at(secondRow.center.dx, secondRow.bottom - 2), theme.link);
      expect(shot.at(secondRow.center.dx, secondRow.bottom - 3), theme.light);
      expect(labelColor(tester, "Second"), theme.link);
      expect(
        shot.at(firstRow.center.dx, firstRow.bottom - 1),
        theme.neutralExtraLight,
      );
      expect(labelColor(tester, "First"), theme.neutralExtraDark);
    });

    testWidgets("puts the message of an invalid row above its red line", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(group(first: first, second: second)),
        fields: _Fields.v2,
      );

      await tester.enterText(find.byKey(first), "bad");
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(second));
      await tester.pumpAndSettle();
      final shot = await screenshot(tester);
      final row = rowRect(tester, 0);
      final value = valueRect(tester);
      final message = tester.getRect(find.text("First is bad"));
      final icon = tester.getRect(find.byIcon(Icons.error));

      // No tint and no coloured left border, as board H3: the row stays white.
      expect(shot.at(row.left + 0.5, row.top + 28), theme.light);
      expect(shot.at(row.center.dx, row.top + 4), theme.light);
      expect(labelColor(tester, "First"), theme.error);

      // The message is inside the row, 2 px below the value and left aligned
      // with it, and the 2 px line is below it, at the bottom of the row.
      expect(message.top - value.bottom, 2);
      expect(message.height, 18);
      expect(icon.left - row.left, 16);
      expect(icon.size, const Size(14, 14));
      expect(icon.right, lessThan(message.left));
      expect(shot.at(row.center.dx, row.bottom - 1), theme.error);
      expect(shot.at(row.center.dx, row.bottom - 2), theme.error);
      expect(shot.at(row.center.dx, row.bottom - 3), theme.light);
      expect(shot.at(row.left + 1, row.bottom - 1), theme.error);
      expect(shot.at(row.right - 2, row.bottom - 1), theme.error);
      expect(message.bottom, lessThan(row.bottom - 2));
      expect(
        shot.columnHas(theme.error, row.center.dx, value.bottom, row.bottom),
        isTrue,
      );
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
        fields: _Fields.legacy,
      );

      expect(
        tester.getTopLeft(find.byKey(second)).dy -
            tester.getBottomLeft(find.byKey(first)).dy,
        theme.mediumSpacing,
      );
    });

    testWidgets("does not rebuild its fields when the flag value arrives", (
      tester,
    ) async {
      await pumpField(
        tester,
        onPage(group(first: first, second: second)),
        fields: _Fields.legacy,
      );
      await tester.tap(find.byKey(first));
      await tester.pumpAndSettle();
      final focus = FocusManager.instance.primaryFocus;
      final before = tester.state(find.byKey(first));

      await prefs.setFeatureFlag(FeatureFlag.formFieldsV2, true);
      await tester.pumpAndSettle();

      expect(tester.state(find.byKey(first)), same(before));
      expect(focus, isNotNull);
      expect(FocusManager.instance.primaryFocus, same(focus));
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
      await pumpField(tester, dateField(), fields: _Fields.v2);

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
        await pumpField(
          tester,
          dateField(),
          fields: _Fields.v2,
          locale: locale,
        );

        expect(find.text(placeholder), findsOneWidget);
      });
    }

    testWidgets("has a 44 px calendar button that fills the field", (
      tester,
    ) async {
      await pumpField(tester, dateField(), fields: _Fields.v2);

      expect(tester.getSize(find.byType(IconButton)), const Size(44, 44));
      expect(find.byTooltip("Choose date"), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();

      final year = DateTime.now().year - 25;
      expect(controller.text, "01-01-$year");
    });

    testWidgets("puts the calendar button 12 px from the top and 8 px from "
        "the end of its row", (tester) async {
      await pumpField(
        tester,
        onPage(
          Form(
            child: YiviFieldGroup(
              children: [
                DateInputField(
                  controller: controller,
                  labelText: "Date of birth",
                  requiredText: "Date of birth is required",
                  dateInvalidText: "Date is invalid",
                ),
              ],
            ),
          ),
        ),
        fields: _Fields.v2,
      );
      final row = tester.getRect(find.byType(YiviTextField));
      final button = tester.getRect(find.byType(IconButton));
      final icon = tester.getRect(find.byIcon(Icons.calendar_today));

      expect(button.size, const Size(44, 44));
      expect(button.top - row.top, 12);
      expect(row.right - button.right, 8);
      expect(icon.size, const Size(22, 22));
      expect(icon.center, button.center);
      expect(row.height, 70);
    });

    testWidgets("is typed as YYYY-MM-DD with the flag off", (tester) async {
      await pumpField(tester, dateField(), fields: _Fields.legacy);

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

    for (final (fields, birth, expiry) in [
      (_Fields.v2, "01021990", "03042030"),
      (_Fields.legacy, "19900201", "20300403"),
    ]) {
      testWidgets("passes the typed dates on with ${fields.name} fields", (
        tester,
      ) async {
        PassportMrzManualEntryData? entered;
        await pumpField(
          tester,
          passportScreen((data) => entered = data),
          fields: fields,
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
      await pumpField(tester, passportScreen((_) {}), fields: _Fields.v2);

      expect(find.byType(YiviFieldGroup), findsOneWidget);
      expect(find.byType(YiviTextField), findsNWidgets(3));
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .style
            .letterSpacing,
        1,
      );
      expect(decorationOf(tester).labelText, "Document number");
      expect(decorationOf(tester).filled, isNot(true));
      expect(find.text("Date of birth"), findsOneWidget);
      expect(find.text("Date of expiry"), findsOneWidget);
    });

    testWidgets("keeps the passport fields apart with the flag off", (
      tester,
    ) async {
      await pumpField(tester, passportScreen((_) {}), fields: _Fields.legacy);

      expect(decorationOf(tester).labelText, isNull);
      expect(decorationOf(tester).label, isA<Text>());
    });

    testWidgets("puts the driving licence field in a card with the flag on", (
      tester,
    ) async {
      await pumpField(
        tester,
        DrivingLicenceMrzManualEntryScreen(onContinue: (_) {}, onCancel: () {}),
        fields: _Fields.v2,
      );

      expect(find.byType(YiviFieldGroup), findsOneWidget);
      expect(decorationOf(tester).labelText, "Machine readable zone (MRZ)");
      expect(decorationOf(tester).filled, isNot(true));
    });

    testWidgets("shows an invalid document number with an icon", (
      tester,
    ) async {
      await pumpField(tester, passportScreen((_) {}), fields: _Fields.v2);

      await tester.enterText(
        find.byKey(const Key("document_nr_input_field")),
        "AB1",
      );
      await tester.pumpAndSettle();

      expect(find.text("Document number is invalid"), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });

  group("feedback dialog", () {
    Future<void> openDialog(
      WidgetTester tester, {
      required _Fields fields,
    }) async {
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
        fields: fields,
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
      await openDialog(tester, fields: _Fields.v2);

      expect(dialogDecoration(tester).labelText, "Your feedback");
      expect(dialogDecoration(tester).hint, isNull);
      expect(dialogDecoration(tester).filled, isTrue);
      expect(find.byWidgetPredicate(hasFeedbackSemantics), findsNothing);
    });

    testWidgets("shows its hint with the flag off", (tester) async {
      await openDialog(tester, fields: _Fields.legacy);

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

    testWidgets("is on the blue page with the flag on", (tester) async {
      await pumpField(
        tester,
        txCodeScreen(),
        fields: _Fields.v2,
        overrides: [session()],
      );

      expect(pageColor(tester), theme.fieldPageBackground);
    });

    testWidgets("shows the wrong code error in the field with the flag on", (
      tester,
    ) async {
      await pumpField(
        tester,
        txCodeScreen(),
        fields: _Fields.v2,
        overrides: [session(remainingAttempts: 2)],
      );

      expect(decorationOf(tester).labelText, "Transaction code");
      expect(
        find.text("Incorrect code. 2 attempts remaining."),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(tester.widget<TextField>(codeField).textAlign, TextAlign.start);
      expect(labelColor(tester, "Transaction code"), theme.error);
    });

    testWidgets("shows no error before a wrong code with the flag on", (
      tester,
    ) async {
      await pumpField(
        tester,
        txCodeScreen(),
        fields: _Fields.v2,
        overrides: [session()],
      );

      expect(find.byIcon(Icons.error), findsNothing);
      expect(labelColor(tester, "Transaction code"), isNot(theme.error));
    });

    testWidgets(
      "shows the wrong code error below the field with the flag off",
      (tester) async {
        await pumpField(
          tester,
          txCodeScreen(),
          fields: _Fields.legacy,
          overrides: [session(remainingAttempts: 2)],
        );

        expect(decorationOf(tester).labelText, isNull);
        expect(
          find.text("Incorrect code. 2 attempts remaining."),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.error), findsNothing);
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
      await pumpField(tester, const EnterEmailScreen(), fields: _Fields.v2);

      final decoration = decorationOf(tester);
      expect(decoration.labelText, "Email address");
      expect(decoration.hintText, "Enter your email address...");
      expect(decoration.filled, isTrue);
    });

    testWidgets("puts the white field on the blue page with the flag on", (
      tester,
    ) async {
      await pumpField(tester, const EnterEmailScreen(), fields: _Fields.v2);
      final shot = await screenshot(tester);
      final rect = decoratorRect(tester);

      // The screen focuses the field when it opens; it stays white.
      expect(pageColor(tester), theme.fieldPageBackground);
      expect(shot.at(rect.left + 20, rect.top + 4), theme.light);
    });

    testWidgets("shows only its hint with the flag off", (tester) async {
      await pumpField(tester, const EnterEmailScreen(), fields: _Fields.legacy);

      final decoration = decorationOf(tester);
      expect(decoration.labelText, isNull);
      expect(decoration.hint, isNotNull);
      expect(decoration.filled, isNot(true));
      expect(pageColor(tester), isNull);
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
      await pumpField(tester, const EnterPhoneScreen(), fields: _Fields.v2);

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

    testWidgets("stays white on the blue page when focused", (tester) async {
      await pumpField(tester, const EnterPhoneScreen(), fields: _Fields.v2);

      await tester.tap(find.byKey(const Key("phone_number_input_field")));
      await tester.pumpAndSettle();
      final shot = await screenshot(tester);
      final rect = tester.getRect(find.byType(core.InputDecorator).first);

      expect(pageColor(tester), theme.fieldPageBackground);
      expect(shot.at(rect.center.dx, rect.top + 4), theme.light);
      expect(shot.at(rect.center.dx, rect.bottom - 1), theme.link);
    });

    testWidgets("shows only its hint with the flag off", (tester) async {
      await pumpField(tester, const EnterPhoneScreen(), fields: _Fields.legacy);

      final decoration = phoneDecoration(tester);
      expect(decoration.labelText, isNull);
      expect(decoration.hint, isNotNull);
      expect(decoration.filled, isNot(true));
    });
  });
}
