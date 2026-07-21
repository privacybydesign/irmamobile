import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/reissue_unavailable_dialog.dart";

class _Host extends StatelessWidget {
  final Locale locale;

  const _Host({this.locale = const Locale("en", "EN")});

  @override
  Widget build(BuildContext context) => IrmaTheme(
    builder: (_) => MaterialApp(
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            basePath: "assets/locales",
            forcedLocale: locale,
          ),
        ),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const ReissueUnavailableDialog(),
              ),
              child: const Text("open"),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Mount [widget] and let FlutterI18nDelegate finish loading the locale JSON
/// (real IO the fake clock does not drive). See signature_message_widget_test.
Future<void> _pumpWithTranslations(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("shows the 'no longer available' title and body", (tester) async {
    await _pumpWithTranslations(tester, const _Host());

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    expect(find.text("This credential is no longer available"), findsOneWidget);
    expect(
      find.text(
        "This credential can no longer be obtained because its issuer is no "
        "longer available.",
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key("dialog_close_button")), findsOneWidget);
  });

  testWidgets("closes when the OK button is tapped", (tester) async {
    await _pumpWithTranslations(tester, const _Host());

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("irma_dialog")), findsOneWidget);

    await tester.tap(find.byKey(const Key("dialog_close_button")));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("irma_dialog")), findsNothing);
    expect(find.text("This credential is no longer available"), findsNothing);
  });

  testWidgets("is localized to Dutch", (tester) async {
    await _pumpWithTranslations(
      tester,
      const _Host(locale: Locale("nl", "NL")),
    );

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    expect(
      find.text("Deze gegevens zijn niet meer beschikbaar"),
      findsOneWidget,
    );
  });
}
