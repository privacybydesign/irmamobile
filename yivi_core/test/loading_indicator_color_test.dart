import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/loading_indicator.dart";

/// Reads the color the circular spinner actually paints with. The painter type
/// is private to the framework, but its `valueColor` field is public, so a
/// dynamic read works and covers the theme fallback too (which
/// `widget.color == null` would not).
Color paintedSpinnerColor(WidgetTester tester) {
  final customPaint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(CircularProgressIndicator),
      matching: find.byType(CustomPaint),
    ),
  );
  return ((customPaint.painter as dynamic).valueColor as Color);
}

void main() {
  Widget host(Widget child) => IrmaTheme(
    builder: (context) => MaterialApp(
      theme: IrmaTheme.of(context).themeData,
      home: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets("LoadingIndicator paints in the primary red", (tester) async {
    await tester.pumpWidget(host(LoadingIndicator()));

    expect(paintedSpinnerColor(tester), IrmaThemeData().primary);
  });

  testWidgets("a bare CircularProgressIndicator paints in the primary red", (
    tester,
  ) async {
    await tester.pumpWidget(host(const CircularProgressIndicator()));

    expect(paintedSpinnerColor(tester), IrmaThemeData().primary);
  });
}
