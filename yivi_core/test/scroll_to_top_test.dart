import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/widgets/scroll_to_top.dart";

Widget _list(ScrollController controller, {Axis axis = Axis.vertical}) =>
    ListView.builder(
      controller: controller,
      scrollDirection: axis,
      itemCount: 100,
      itemBuilder: (_, i) => SizedBox(height: 60, width: 60, child: Text("$i")),
    );

void main() {
  testWidgets("a list in sight goes back to its top", (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: _list(controller))),
    );
    controller.jumpTo(900);
    await tester.pump();

    scrollListsToTop(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
  });

  testWidgets("a list covered by something else is left alone", (tester) async {
    final under = ScrollController();
    addTearDown(under.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              _list(under),
              // A sheet over all of it.
              const Positioned.fill(child: ColoredBox(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
    under.jumpTo(900);
    await tester.pump();

    scrollListsToTop(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
    expect(under.offset, 900);
  });

  testWidgets("a list out of sight (Offstage) is left alone", (tester) async {
    final hidden = ScrollController();
    addTearDown(hidden.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Offstage(child: _list(hidden))),
      ),
    );
    hidden.jumpTo(900);
    await tester.pump();

    scrollListsToTop(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
    expect(hidden.offset, 900);
  });

  testWidgets("a list across is left alone", (tester) async {
    final across = ScrollController();
    addTearDown(across.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _list(across, axis: Axis.horizontal)),
      ),
    );
    across.jumpTo(900);
    await tester.pump();

    scrollListsToTop(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
    expect(across.offset, 900);
  });

  testWidgets("a tap on the status bar scrolls the list up", (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => StatusBarScrollsToTop(child: child!),
        home: Scaffold(body: _list(controller)),
      ),
    );
    controller.jumpTo(900);
    await tester.pump();

    // As the iOS engine sends it: a message, not a touch.
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.statusBar.name,
      SystemChannels.statusBar.codec.encodeMethodCall(
        const MethodCall("handleScrollToTop"),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
  });
}
