import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/data/card_transition/card_transition.dart";
import "package:yivi_core/src/screens/data/card_transition/card_transition_layer.dart";
import "package:yivi_core/src/screens/data/card_transition/choreography.dart";
import "package:yivi_core/src/theme/theme.dart";

void main() {
  final transitions = GlobalKey<CardTransitionsState>();
  final details = ScrollController();

  /// The home screen with the open-card layer, a card opening from the
  /// middle of the screen to the top of long details.
  Future<CardTransition> open(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      IrmaTheme(
        builder: (_) => MaterialApp(
          home: CardTransitions(
            key: transitions,
            child: const Stack(
              children: [
                SizedBox.expand(),
                Positioned.fill(child: OpenCardLayer()),
              ],
            ),
          ),
        ),
      ),
    );
    transitions.currentState!.open(
      snapshot: const TransitionSnapshot(
        picked: 0,
        cards: [Rect.fromLTWH(16, 400, 368, 232)],
        target: Rect.fromLTWH(16, 80, 368, 232),
        screenHeight: 844,
      ),
      details: (context, t) => ListView(
        controller: details,
        padding: const EdgeInsets.only(top: 80),
        children: [
          Center(child: SizedBox(key: t.cardKey, width: 368, height: 232)),
          for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text("$i")),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    return transitions.currentState!.current.value!;
  }

  testWidgets("pushed up as it opens, nearly there: open at once, and the "
      "finger scrolls the details", (tester) async {
    final t = await open(tester);
    await tester.pump(const Duration(milliseconds: 220));
    expect(t.phase, TransitionPhase.opening);
    final gesture = await tester.startGesture(const Offset(200, 600));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(t.phase, TransitionPhase.open);
    expect(details.offset, greaterThan(100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(t.phase, TransitionPhase.open);
  });

  testWidgets("pushed up right after the tap, still far: the card is held", (
    tester,
  ) async {
    final t = await open(tester);
    await tester.pump(const Duration(milliseconds: 30));
    final gesture = await tester.startGesture(const Offset(200, 600));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump(const Duration(milliseconds: 16));
    expect(t.held, isTrue);
    expect(details.offset, 0);
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
