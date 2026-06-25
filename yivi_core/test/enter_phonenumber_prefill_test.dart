import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/sms/widgets/enter_phonenumber_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

class _TestApp extends StatelessWidget {
  final String? prefillPhoneNumber;

  const _TestApp({this.prefillPhoneNumber});

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
        home: EnterPhoneScreen(prefillPhoneNumber: prefillPhoneNumber),
      ),
    ),
  );
}

String _digitsOnly(String value) => value.replaceAll(RegExp(r"[^0-9]"), "");

void main() {
  testWidgets("pre-fills the input with the requested phone number", (
    tester,
  ) async {
    await tester.pumpWidget(const _TestApp(prefillPhoneNumber: "+31612345678"));
    // The number is parsed and filled in a post-frame callback, so let the
    // frame settle.
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    final text = field.controller?.text ?? "";
    // The field shows the nationally-formatted number (spacing may vary), so
    // assert on the significant digits the verifier requested.
    expect(_digitsOnly(text), "612345678");
  });

  testWidgets("leaves the input empty when no phone number was requested", (
    tester,
  ) async {
    await tester.pumpWidget(const _TestApp());
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.controller?.text ?? "", "");
  });
}
