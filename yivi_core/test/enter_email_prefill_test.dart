import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/email/widgets/enter_email_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

class _TestApp extends StatelessWidget {
  final String? prefillEmail;

  const _TestApp({this.prefillEmail});

  @override
  Widget build(BuildContext context) => ProviderScope(
    child: IrmaTheme(
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
        home: EnterEmailScreen(prefillEmail: prefillEmail),
      ),
    ),
  );
}

void main() {
  const emailFieldKey = Key("email_input_field");

  testWidgets("pre-fills the input with the requested email address", (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(prefillEmail: "john.doe@example.com"),
    );
    // The field is filled in a post-frame callback, so let the frame settle.
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(find.byKey(emailFieldKey));
    expect(field.controller?.text, "john.doe@example.com");
    expect(find.text("john.doe@example.com"), findsOneWidget);
  });

  testWidgets("leaves the input empty when no email was requested", (
    tester,
  ) async {
    await tester.pumpWidget(const _TestApp());
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(find.byKey(emailFieldKey));
    expect(field.controller?.text, "");
  });
}
