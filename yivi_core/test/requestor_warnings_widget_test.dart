import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/requestor_warnings.dart";

class _Host extends StatelessWidget {
  final List<SessionWarning> warnings;
  final Locale locale;

  const _Host(this.warnings, {this.locale = const Locale("en", "EN")});

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
      home: Scaffold(body: RequestorWarnings(warnings: warnings)),
    ),
  );
}

// The loader reads locale JSON via real IO that the fake test clock doesn't
// drive, so pumpAndSettle alone sees no translated text. runAsync drives real
// time so the file reads complete. Mirrors signature_message_widget_test.
Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

void main() {
  const invalidText =
      "Yivi could not confirm a secure connection to this organization. "
      "Only share your data if you trust this request.";

  testWidgets("shows a warning box for a failed DNSSEC check", (tester) async {
    await _pump(tester, const _Host([SessionWarning.didWebDnssecInvalid]));
    expect(find.text(invalidText), findsOneWidget);
  });

  testWidgets("renders nothing when there are no warnings", (tester) async {
    await _pump(tester, const _Host([]));
    expect(find.byType(Icon), findsNothing);
    expect(find.text(invalidText), findsNothing);
  });

  testWidgets("does not surface a missing-DNSSEC warning", (tester) async {
    await _pump(tester, const _Host([SessionWarning.didWebDnssecMissing]));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets("ignores unknown warning codes", (tester) async {
    await _pump(tester, const _Host([SessionWarning.unknown]));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets("localizes the warning to Dutch", (tester) async {
    await _pump(
      tester,
      const _Host([
        SessionWarning.didWebDnssecInvalid,
      ], locale: Locale("nl", "NL")),
    );
    expect(
      find.textContaining("Deel je gegevens alleen als je deze aanvraag"),
      findsOneWidget,
    );
  });
}
