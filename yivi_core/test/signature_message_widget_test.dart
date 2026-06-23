import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/signature_message_text.dart";
import "package:yivi_core/src/widgets/irma_quote.dart";
import "package:yivi_core/src/widgets/signature_message.dart";

class _Host extends StatelessWidget {
  final String message;
  final Locale locale;

  const _Host(this.message, {this.locale = const Locale("en", "EN")});

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
        body: SingleChildScrollView(child: SignatureMessage(message: message)),
      ),
    ),
  );
}

void main() {
  final textFinder = find.byKey(const Key("signature_message_text"));
  final toggleFinder = find.byKey(const Key("signature_message_toggle"));

  // A message longer than the inline preview limit, including a long unbroken
  // run of non-whitespace — the shape that froze the UI in issue #294.
  final longMessage = "${"0123456789" * 700} end";

  Text shownText(WidgetTester tester) => tester.widget<Text>(textFinder);

  testWidgets("short message renders in full without a Read more link", (
    tester,
  ) async {
    await tester.pumpWidget(const _Host("A short message to sign"));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("signature_message")), findsOneWidget);
    expect(toggleFinder, findsNothing);
    // Short messages keep the plain markdown `quote`, unchanged.
    final quote = tester.widget<IrmaQuote>(
      find.byKey(const Key("signature_message")),
    );
    expect(quote.quote, "A short message to sign");
  });

  testWidgets(
    "long message truncates to a few lines with an ellipsis and a Read more link",
    (tester) async {
      await tester.pumpWidget(_Host(longMessage));
      await tester.pumpAndSettle();

      expect(find.text("Read more"), findsOneWidget);
      expect(find.text("Read less"), findsNothing);

      final collapsed = shownText(tester);
      expect(collapsed.maxLines, isNotNull);
      expect(collapsed.overflow, TextOverflow.ellipsis);
      expect(collapsed.data!.runes.length, lessThan(longMessage.runes.length));
    },
  );

  testWidgets("tapping Read more expands and Read less collapses again", (
    tester,
  ) async {
    await tester.pumpWidget(_Host(longMessage));
    await tester.pumpAndSettle();

    final collapsedLength = shownText(tester).data!.runes.length;

    // Click the "Read more" link.
    await tester.ensureVisible(toggleFinder);
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    expect(find.text("Read less"), findsOneWidget);
    expect(find.text("Read more"), findsNothing);

    final expanded = shownText(tester);
    expect(expanded.maxLines, isNull);
    expect(expanded.data!.runes.length, greaterThan(collapsedLength));
    // The full message is now present (zero-width break opportunities removed).
    expect(
      expanded.data!.replaceAll(zeroWidthSpace, "").contains(longMessage),
      isTrue,
    );

    // Click the "Read less" link.
    await tester.ensureVisible(toggleFinder);
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    expect(find.text("Read more"), findsOneWidget);
    expect(find.text("Read less"), findsNothing);
  });

  testWidgets("Read more link is localized to Dutch", (tester) async {
    await tester.pumpWidget(
      _Host(longMessage, locale: const Locale("nl", "NL")),
    );
    await tester.pumpAndSettle();

    expect(find.text("Meer lezen"), findsOneWidget);

    await tester.ensureVisible(toggleFinder);
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    expect(find.text("Minder lezen"), findsOneWidget);
  });
}
