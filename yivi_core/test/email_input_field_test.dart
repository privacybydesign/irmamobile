import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/enrollment/provide_email/widgets/email_input_field.dart";
import "package:yivi_core/src/theme/theme.dart";

class _Host extends StatelessWidget {
  final TextEditingController controller;

  const _Host(this.controller);

  @override
  Widget build(BuildContext context) => IrmaTheme(
    builder: (_) => MaterialApp(
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            basePath: "assets/locales",
            forcedLocale: const Locale("en", "EN"),
          ),
        ),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: EmailInputField(controller: controller)),
    ),
  );
}

/// Mount [widget] and wait for FlutterI18nDelegate to finish loading the
/// locale JSON (real-time IO the fake clock doesn't drive — see
/// signature_message_widget_test.dart for the same pattern).
Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    "EmailInputField requests the email-optimised keyboard so the @ key is available",
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pump(tester, _Host(controller));

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key("email_input_field")),
          matching: find.byType(TextField),
        ),
      );

      // The email keyboard (with a dedicated "@" key) is requested via the
      // emailAddress input type. Pinning it here prevents a silent regression
      // back to the default text keyboard, which on some Android devices hides
      // the "@" symbol (issue #607).
      expect(field.keyboardType, TextInputType.emailAddress);

      // Email-optimised input configuration, kept consistent with the embedded
      // issuance email field (enter_email_screen.dart): no autocapitalisation,
      // autocorrect or word suggestions mangling the address.
      expect(field.textCapitalization, TextCapitalization.none);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.autofillHints, contains(AutofillHints.email));
    },
  );
}
