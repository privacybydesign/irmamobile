import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/util/adaptive_layout.dart";
import "package:yivi_core/src/widgets/glass/glass_sheet.dart";

void main() {
  /// Opens a sheet in a window of [size]; returns the sheet's width and
  /// whether its content uses two columns.
  Future<(double, bool)> open(WidgetTester tester, Size size) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    late BuildContext page;
    double? width;
    bool? columns;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            page = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );
    showGlassSheet<void>(
      context: page,
      // The sheet's content, built inside the sheet.
      builder: (_) => Builder(
        builder: (context) {
          width = SheetWidthScope.of(context);
          columns = useSheetColumns(context);
          return const SizedBox.expand();
        },
      ),
    );
    await tester.pumpAndSettle();
    return (width!, columns!);
  }

  testWidgets("a phone held upright: one column", (tester) async {
    expect((await open(tester, const Size(402, 874))).$2, isFalse);
  });

  testWidgets("an unfolded phone held upright: a 540 form sheet, one column", (
    tester,
  ) async {
    final (width, columns) = await open(tester, const Size(867, 1232));
    expect(width, 540);
    expect(columns, isFalse);
  });

  testWidgets("the smallest phone held sideways: two columns", (tester) async {
    expect((await open(tester, const Size(667, 375))).$2, isTrue);
  });

  testWidgets("an 11-inch iPad held upright: a 540 form sheet, one column", (
    tester,
  ) async {
    final (width, columns) = await open(tester, const Size(820, 1180));
    expect(width, 540);
    expect(columns, isFalse);
  });

  testWidgets("a 13-inch iPad held upright: 540, one column", (tester) async {
    final (width, columns) = await open(tester, const Size(1024, 1366));
    expect(width, 540);
    expect(columns, isFalse);
  });

  testWidgets("a tablet held sideways: 540, one column", (tester) async {
    final (width, columns) = await open(tester, const Size(1232, 867));
    expect(width, 540);
    expect(columns, isFalse);
  });
}
