import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/widgets/glass/glass_search_field.dart";

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

  final field = find.byKey(const Key("search_field"));
  final pill = find.byType(GlassSearchField);

  Future<void> pump(WidgetTester tester, {FocusNode? focusNode}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpHome(
      tester,
      repo: repo,
      home: Padding(
        padding: const EdgeInsets.fromLTRB(16, 100, 16, 0),
        child: Align(
          alignment: Alignment.topCenter,
          child: GlassSearchField(
            fieldKey: const Key("search_field"),
            hintKey: "wallet.search_placeholder",
            focusNode: focusNode,
            onChanged: (_) {},
          ),
        ),
      ),
    );
  }

  bool focused(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

  // The whole pill is the field: a tap on the magnifier, near its top or
  // bottom edge, or at its far end focuses it the first time.
  for (final (name, at) in [
    ("the magnifier", (Rect r) => Offset(r.left + 26, r.center.dy)),
    ("near the top edge", (Rect r) => Offset(r.center.dx, r.top + 4)),
    ("near the bottom edge", (Rect r) => Offset(r.center.dx, r.bottom - 4)),
    ("the far end", (Rect r) => Offset(r.right - 8, r.center.dy)),
  ]) {
    testWidgets("one tap on $name focuses the field", (tester) async {
      await pump(tester);
      await tester.tapAt(at(tester.getRect(pill)));
      await tester.pump();
      expect(focused(tester), isTrue);
    });
  }

  testWidgets("a given focus node is the one focused", (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await pump(tester, focusNode: node);
    await tester.tapAt(tester.getRect(pill).topLeft + const Offset(26, 4));
    await tester.pump();
    expect(node.hasFocus, isTrue);
  });

  testWidgets("clearing after the keyboard went gives it back", (tester) async {
    await pump(tester);
    await tester.enterText(field, "mail");
    await tester.pump();
    // The search key puts the keyboard away; the text stays.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(focused(tester), isFalse);

    await tester.tap(
      find.descendant(of: pill, matching: find.byIcon(Icons.close)),
    );
    await tester.pump();
    expect(find.text("mail"), findsNothing);
    expect(focused(tester), isTrue);
  });

  testWidgets("typing still works after a tap on the edge", (tester) async {
    await pump(tester);
    await tester.tapAt(tester.getRect(pill).topLeft + const Offset(26, 4));
    await tester.pump();
    await tester.enterText(field, "mail");
    expect(find.text("mail"), findsOneWidget);
  });
}
