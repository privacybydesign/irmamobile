import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/enrollment/provide_email/provide_email_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

import "helpers/test_translation_loader.dart";

void main() {
  const rejectedMessage =
      "We can't send an e-mail to this address. Check the spelling.";
  final emailField = find.byKey(const Key("email_input_field"));

  Future<void> pumpScreen(
    WidgetTester tester, {
    String? email,
    String? rejectedEmail,
  }) async {
    final widget = ProviderScope(
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
          home: ProvideEmailScreen(
            email: email,
            rejectedEmail: rejectedEmail,
            onEmailProvided: (_) {},
            onEmailSkipped: () {},
            onPrevious: () {},
          ),
        ),
      ),
    );

    // The locale JSON loads with real IO, which the fake clock does not drive.
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  testWidgets("shows the address and a message under it when rejected", (
    tester,
  ) async {
    await pumpScreen(
      tester,
      email: "jan@caeser.nl",
      rejectedEmail: "jan@caeser.nl",
    );

    expect(
      find.descendant(of: emailField, matching: find.text("jan@caeser.nl")),
      findsOneWidget,
    );
    expect(find.text(rejectedMessage), findsOneWidget);
  });

  testWidgets("clears the message once the address is edited", (tester) async {
    await pumpScreen(
      tester,
      email: "jan@caeser.nl",
      rejectedEmail: "jan@caeser.nl",
    );

    await tester.enterText(emailField, "jan@caesar.nl");
    await tester.pumpAndSettle();

    expect(find.text(rejectedMessage), findsNothing);
  });

  testWidgets("shows no message for an address that was not rejected", (
    tester,
  ) async {
    await pumpScreen(tester, email: "jan@caesar.nl");

    expect(find.text(rejectedMessage), findsNothing);
  });
}
