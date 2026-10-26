import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/more/more_tab.dart";

import "support/onboarding_v2_harness.dart";

void main() {
  late IrmaRepository repo;

  setUp(() async {
    repo = IrmaRepository(
      client: RecordingBridge(),
      preferences: await freshPreferences(),
    );
  });
  tearDown(() => repo.close());

  // The band under the top comes with the small title, not on the first
  // scroll: before that only the large title is there.
  testWidgets("More: the band comes and goes with the small title", (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      home: BlocProvider<HomeTabState>(
        create: (_) => HomeTabState(),
        child: MoreTab(onChangeTab: (_) {}),
      ),
    );
    await settle(tester);
    await tester.pumpAndSettle();

    final band = find.byKey(const Key("scroll_edge_band"));
    final title = find.byKey(const Key("title_scroll_edge_title"));
    double titleOpacity() => tester.widget<AnimatedOpacity>(title).opacity;
    final scroll = find.byType(Scrollable).first;

    expect(band, findsNothing);
    await tester.drag(scroll, const Offset(0, -10));
    await tester.pumpAndSettle();
    expect(titleOpacity(), 0);
    expect(band, findsNothing);

    await tester.drag(scroll, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(titleOpacity(), 1);
    expect(band, findsOneWidget);

    await tester.drag(scroll, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(titleOpacity(), 0);
    expect(band, findsNothing);
  });
}
