import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/email/widgets/enter_email_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/radio_indicator.dart";
import "package:yivi_core/src/widgets/yivi_themed_button.dart";

class _TestApp extends StatelessWidget {
  final List<String> requestedEmails;

  const _TestApp({this.requestedEmails = const []});

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
        home: EnterEmailScreen(requestedEmails: requestedEmails),
      ),
    ),
  );
}

void main() {
  const emailFieldKey = Key("email_input_field");
  const primaryButtonKey = Key("bottom_bar_primary");

  bool primaryEnabled(WidgetTester tester) =>
      tester.widget<YiviThemedButton>(find.byKey(primaryButtonKey)).onPressed !=
      null;

  testWidgets("locks the input to a single requested email address", (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(requestedEmails: ["john.doe@example.com"]),
    );
    await tester.pumpAndSettle();

    // There is no free-text field: the requested address cannot be edited.
    expect(find.byKey(emailFieldKey), findsNothing);
    // The requested address is shown and, being the only choice, preselected.
    expect(find.text("john.doe@example.com"), findsOneWidget);
    expect(primaryEnabled(tester), isTrue);
    // With nothing to choose there are no radio controls either.
    expect(find.byType(RadioIndicator), findsNothing);
  });

  testWidgets("requires choosing one of multiple requested addresses", (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        requestedEmails: ["john.doe@example.com", "j.doe@work.example.com"],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(emailFieldKey), findsNothing);
    expect(find.text("john.doe@example.com"), findsOneWidget);
    expect(find.text("j.doe@work.example.com"), findsOneWidget);
    expect(find.byType(RadioIndicator), findsNWidgets(2));

    // No address is preselected, so the user cannot proceed yet.
    expect(primaryEnabled(tester), isFalse);

    await tester.tap(find.byKey(const Key("requested_email_option_1")));
    await tester.pumpAndSettle();

    expect(primaryEnabled(tester), isTrue);
  });

  testWidgets("shows an empty editable field when no email was requested", (
    tester,
  ) async {
    await tester.pumpWidget(const _TestApp());
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(find.byKey(emailFieldKey));
    expect(field.controller?.text, "");
  });

  testWidgets("ignores requested values that are not email addresses", (
    tester,
  ) async {
    // A verifier may constrain other attributes of the credential too (e.g.
    // the domain); those values must not lock or seed the email input.
    await tester.pumpWidget(
      const _TestApp(requestedEmails: ["john.doe@example.com", "example.com"]),
    );
    await tester.pumpAndSettle();

    // Only the actual email address remains: a single locked value.
    expect(find.byKey(emailFieldKey), findsNothing);
    expect(find.text("john.doe@example.com"), findsOneWidget);
    expect(find.text("example.com"), findsNothing);
    expect(primaryEnabled(tester), isTrue);
  });

  testWidgets("falls back to the editable field when no requested value is "
      "an email address", (tester) async {
    await tester.pumpWidget(const _TestApp(requestedEmails: ["example.com"]));
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(find.byKey(emailFieldKey));
    expect(field.controller?.text, "");
  });
}
