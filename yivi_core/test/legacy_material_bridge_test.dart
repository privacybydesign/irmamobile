import "package:flutter/material.dart" as core;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:pinput/pinput.dart";
import "package:yivi_core/app.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/irma_markdown.dart";
import "package:yivi_core/src/widgets/legacy_material_bridge.dart";

// Flutter 3.47 unbundled the Material and Cupertino widget libraries and the app
// moved to package:material_ui, so a material_ui MaterialApp no longer installs
// the core SDK Theme, localizations and Material that packages which have not
// migrated yet look up. LegacyMaterialBridge puts them back; without it pinput's
// asserts fail on the email, SMS and transaction-code screens, and everything
// else silently renders with Material's default theme instead of the Yivi one.

/// The app tree around [child], as [App] builds it: a `material_ui`
/// [MaterialApp] carrying the Yivi theme, bridged for legacy widgets.
Widget _app({required Widget child, required bool bridge}) {
  return IrmaTheme(
    builder: (context) => MaterialApp(
      theme: IrmaTheme.of(context).themeData,
      localizationsDelegates: AppState.defaultLocalizationsDelegates(
        const Locale("en", "US"),
      ),
      supportedLocales: AppState.defaultSupportedLocales(),
      builder: bridge
          ? (context, child) => LegacyMaterialBridge(child: child!)
          : null,
      home: child,
    ),
  );
}

void main() {
  testWidgets("legacy widgets see the Yivi theme through the bridge", (
    tester,
  ) async {
    late core.ThemeData coreTheme;

    await tester.pumpWidget(
      _app(
        bridge: true,
        child: core.Builder(
          builder: (context) {
            coreTheme = core.Theme.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final yiviFontFamily = IrmaThemeData().textTheme.bodyMedium?.fontFamily;
    expect(yiviFontFamily, isNotNull);
    expect(coreTheme.colorScheme.primary, IrmaThemeData().primary);
    expect(coreTheme.textTheme.bodyMedium?.fontFamily, yiviFontFamily);
  });

  testWidgets("markdown keeps the Yivi body text style", (tester) async {
    await tester.pumpWidget(
      _app(bridge: true, child: const IrmaMarkdown("hello world")),
    );
    await tester.pumpAndSettle();

    // IrmaMarkdown now reads the core SDK theme, because flutter_markdown's
    // MarkdownStyleSheet.fromTheme still takes the core SDK ThemeData.
    final paragraph = tester.widget<RichText>(find.byType(RichText).first);
    final bodyMedium = IrmaThemeData().textTheme.bodyMedium!;
    expect(
      (paragraph.text as TextSpan).style?.fontFamily,
      bodyMedium.fontFamily,
    );
    expect((paragraph.text as TextSpan).style?.fontSize, bodyMedium.fontSize);
  });

  testWidgets("a legacy widget builds inside the app tree", (tester) async {
    await tester.pumpWidget(
      _app(bridge: true, child: Pinput(length: 4, autofocus: false)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Pinput), findsOneWidget);
  });

  testWidgets("without the bridge a legacy widget cannot build", (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(bridge: false, child: Pinput(length: 4, autofocus: false)),
    );
    await tester.pumpAndSettle();

    // pinput asserts a core SDK Material ancestor, which the material_ui
    // Scaffold and MaterialApp no longer are.
    expect(
      tester.takeException(),
      isA<core.FlutterError>().having(
        (e) => e.message,
        "message",
        contains("Material widget"),
      ),
    );
  });
}
