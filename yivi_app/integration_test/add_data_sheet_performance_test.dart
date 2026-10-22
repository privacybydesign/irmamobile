import "package:flutter/scheduler.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/add_data/add_data_sheet.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";

import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

/// Measures the Add data sheet: the frames of opening it, scrolling its list,
/// opening a type and going back, and searching. Prints a `PERF` line per
/// action (build and raster times, frames over budget); it asserts nothing.
///
/// On the simulator only the build times say something, and in debug mode
/// they are inflated: compare runs, not numbers. On a device, run it in
/// profile mode for real numbers.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();

  Future<void> measure(
    WidgetTester tester,
    String name,
    Future<void> Function() action,
  ) async {
    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> t) => timings.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(collect);
    await action();
    // The engine reports timings in batches; let the last ones come in.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    SchedulerBinding.instance.removeTimingsCallback(collect);
    if (timings.isEmpty) {
      debugPrint("PERF $name no frames");
      return;
    }
    final s = FrameTimingSummarizer(timings);
    String ms(Duration d) => (d.inMicroseconds / 1000).toStringAsFixed(1);
    debugPrint(
      "PERF $name frames=${timings.length}"
      " build avg=${ms(s.averageFrameBuildTime)}"
      " p90=${ms(s.p90FrameBuildTime)}"
      " worst=${ms(s.worstFrameBuildTime)}"
      " over=${s.missedFrameBuildBudget}"
      " | raster avg=${ms(s.averageFrameRasterizerTime)}"
      " p90=${ms(s.p90FrameRasterizerTime)}"
      " worst=${ms(s.worstFrameRasterizerTime)}"
      " over=${s.missedFrameRasterizerBudget}",
    );
  }

  testWidgets("add data sheet", (tester) async {
    await irmaBinding.setUp();
    await pumpAndUnlockApp(tester, irmaBinding.repository);

    // The list: the scroll view around its rows.
    final list = find
        .ancestor(
          of: find.byType(AddDataRow).first,
          matching: find.byType(Scrollable),
        )
        .first;

    await measure(tester, "open", () async {
      await tester.tap(
        find.descendant(
          of: find.byType(DataTab),
          matching: find.byIcon(Icons.add),
        ),
      );
      await tester.pumpAndSettle();
    });

    // The list comes once the store is loaded (its rows are built as they
    // come into view).
    await tester.waitFor(find.byType(AddDataRow));

    await measure(tester, "scroll", () async {
      for (var i = 0; i < 3; i++) {
        await tester.fling(list, const Offset(0, -2500), 3000);
        await tester.pumpAndSettle();
      }
      // Back up in drags that stop at the top: past it, the pull closes
      // the sheet.
      final position = tester.state<ScrollableState>(list).position;
      while (position.pixels > 700) {
        await tester.drag(list, const Offset(0, 600));
        await tester.pumpAndSettle();
      }
      position.jumpTo(0);
      await tester.pumpAndSettle();
    });

    final tile = find.byKey(const Key("pbdf-staging.sidn-pbdf.email_tile"));
    await measure(tester, "open-type-and-back", () async {
      for (var i = 0; i < 3; i++) {
        await tester.scrollUntilVisible(tile, 300, scrollable: list);
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel("Go back").last);
        await tester.pumpAndSettle();
      }
    });

    await irmaBinding.tearDown();
  });
}
