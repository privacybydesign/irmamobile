import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/irma_icon_button.dart";

class _Host extends StatelessWidget {
  final String? semanticsLabelKey;
  final Locale locale;

  const _Host({this.semanticsLabelKey, this.locale = const Locale("en", "EN")});

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
      home: Scaffold(
        body: IrmaIconButton(
          icon: CupertinoIcons.add_circled_solid,
          semanticsLabelKey: semanticsLabelKey,
          onTap: () {},
        ),
      ),
    ),
  );
}

/// Mount [widget] and wait for FlutterI18nDelegate to finish loading the
/// locale + fallback JSON. The loader reads via rootBundle.loadString — real
/// IO that the fake clock doesn't drive, so we run it under real time. See
/// signature_message_widget_test.dart for the same pattern.
Future<void> _pumpWithTranslations(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("add-data button exposes a localized semantics label (nl)", (
    tester,
  ) async {
    await _pumpWithTranslations(
      tester,
      const _Host(
        semanticsLabelKey: "accessibility.add_data",
        locale: Locale("nl", "NL"),
      ),
    );

    final node = tester.getSemantics(find.byType(IrmaIconButton));
    expect(node.label, "Voeg gegevens toe");
  });

  testWidgets("add-data button exposes a localized semantics label (en)", (
    tester,
  ) async {
    await _pumpWithTranslations(
      tester,
      const _Host(semanticsLabelKey: "accessibility.add_data"),
    );

    final node = tester.getSemantics(find.byType(IrmaIconButton));
    expect(node.label, "Add data");
  });

  testWidgets("add-data button exposes a localized semantics label (de)", (
    tester,
  ) async {
    await _pumpWithTranslations(
      tester,
      const _Host(
        semanticsLabelKey: "accessibility.add_data",
        locale: Locale("de", "DE"),
      ),
    );

    final node = tester.getSemantics(find.byType(IrmaIconButton));
    expect(node.label, "Daten hinzufügen");
  });

  testWidgets("button is still flagged as a button for screen readers", (
    tester,
  ) async {
    await _pumpWithTranslations(
      tester,
      const _Host(semanticsLabelKey: "accessibility.add_data"),
    );

    final node = tester.getSemantics(find.byType(IrmaIconButton));
    expect(node.flagsCollection.isButton, isTrue);
  });
}
