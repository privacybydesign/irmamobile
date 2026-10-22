import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/glass/glass_sheet.dart";
import "package:yivi_core/src/widgets/glass/glass_surface.dart";
import "package:yivi_core/src/widgets/irma_close_button.dart";

import "helpers/test_translation_loader.dart";

late BuildContext _page;

Widget _app() => IrmaTheme(
  builder: (_) => MaterialApp(
    localizationsDelegates: [
      FlutterI18nDelegate(
        translationLoader: TestTranslationLoader(
          basePath: "assets/locales",
          forcedLocale: const Locale("en", "US"),
        ),
      ),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Builder(
      builder: (context) {
        _page = context;
        return const Scaffold(body: Center(child: Text("page")));
      },
    ),
  ),
);

/// A sheet whose list is taller than the sheet.
void _open() => showGlassSheet<void>(
  context: _page,
  builder: (_) => GlassSheetPage(
    title: "Sheet",
    child: Column(children: [for (var i = 0; i < 40; i++) Text("row $i")]),
  ),
);

/// A sheet that asks before closing; [answer] is what the question returns.
int _asked = 0;
void _openGuarded({required bool answer}) {
  _asked = 0;
  showGlassSheet<void>(
    context: _page,
    builder: (_) => GlassSheetConfirmDismiss(
      ask: true,
      confirm: () async {
        _asked++;
        return answer;
      },
      child: GlassSheetPage(
        title: "Sheet",
        child: Column(children: [for (var i = 0; i < 40; i++) Text("row $i")]),
      ),
    ),
  );
}

bool _gestureStuck(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator)).userGestureInProgress;

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(400, 800);
    view.devicePixelRatio = 1;
    // A status bar: the sheet starts under it, as on a phone.
    view.padding = const FakeViewPadding(top: 47);
  });
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .resetPadding(),
  );

  testWidgets("as tall as a native iOS sheet: its top at the top inset", (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    _open();
    await tester.pumpAndSettle();
    final sheet = tester.getRect(find.byType(GlassSheetPage));
    expect(sheet.top, 47);
    expect(sheet.bottom, 800);
  });

  testWidgets("a pull taken back before letting go ends the gesture", (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    _open();
    await tester.pumpAndSettle();

    final g = await tester.startGesture(tester.getCenter(find.text("row 2")));
    await g.moveBy(const Offset(0, 40));
    await tester.pump();
    await g.moveBy(const Offset(0, 40));
    await tester.pump();
    // Back up past where it started: the pull is gone, the list scrolls.
    await g.moveBy(const Offset(0, -200));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();

    expect(_gestureStuck(tester), isFalse);
    expect(find.text("Sheet"), findsOneWidget);
    // Still answers taps: the close button closes it.
    await tester.tap(find.byType(IrmaCloseButton));
    await tester.pumpAndSettle();
    expect(find.text("Sheet"), findsNothing);
  });

  testWidgets("a pull let go closes or springs back, and ends the gesture", (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    _open();
    await tester.pumpAndSettle();
    await tester.drag(find.text("row 2"), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(find.text("Sheet"), findsOneWidget);
    expect(_gestureStuck(tester), isFalse);

    await tester.drag(find.text("row 2"), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text("Sheet"), findsNothing);
    expect(_gestureStuck(tester), isFalse);
  });

  testWidgets("a drag on the header that is cancelled ends the gesture", (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    _open();
    await tester.pumpAndSettle();

    final g = await tester.startGesture(tester.getCenter(find.text("Sheet")));
    await g.moveBy(const Offset(0, 40));
    await tester.pump();
    await g.moveBy(const Offset(0, 40));
    await tester.pump();
    await g.cancel();
    await tester.pumpAndSettle();

    expect(_gestureStuck(tester), isFalse);
    expect(find.text("Sheet"), findsOneWidget);
  });

  testWidgets("screen readers see the sheet's title, close button and rows", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    _open();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel("Sheet"), findsOneWidget);
    expect(find.bySemanticsLabel("Close"), findsOneWidget);
    expect(find.bySemanticsLabel("row 2"), findsOneWidget);
    semantics.dispose();
  });

  group("a sheet that asks before closing", () {
    Future<void> open(WidgetTester tester, {required bool answer}) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      _openGuarded(answer: answer);
      await tester.pumpAndSettle();
    }

    // Each way the sheet can be closed, and what it does.
    final ways = <String, Future<void> Function(WidgetTester)>{
      // The sheet is as tall as on iOS: its top edge is at the status
      // bar's bottom (47), so the status bar is outside it.
      "a tap outside it": (tester) => tester.tapAt(const Offset(200, 3)),
      "its close button": (tester) => tester.tap(find.byType(IrmaCloseButton)),
      "the system back": (tester) async {
        await tester.binding.handlePopRoute();
      },
    };

    for (final MapEntry(key: way, value: close) in ways.entries) {
      testWidgets("$way asks, and stays open on no", (tester) async {
        await open(tester, answer: false);
        await close(tester);
        await tester.pumpAndSettle();
        expect(_asked, 1);
        expect(find.text("Sheet"), findsOneWidget);
        expect(_gestureStuck(tester), isFalse);
      });

      testWidgets("$way asks, and closes on yes", (tester) async {
        await open(tester, answer: true);
        await close(tester);
        await tester.pumpAndSettle();
        expect(_asked, 1);
        expect(find.text("Sheet"), findsNothing);
        expect(_gestureStuck(tester), isFalse);
      });
    }

    // Something important happens in it: a drag does not move it at all.
    final drags = <String, Finder>{
      "a drag down on its header": find.text("Sheet"),
      "a pull of its list": find.text("row 2"),
    };
    for (final MapEntry(key: way, value: start) in drags.entries) {
      testWidgets("$way does not move it, and asks nothing", (tester) async {
        await open(tester, answer: false);
        final top = tester.getRect(find.byType(GlassSheetPage)).top;
        final g = await tester.startGesture(tester.getCenter(start));
        for (var i = 0; i < 6; i++) {
          await g.moveBy(const Offset(0, 60));
          await tester.pump();
          expect(tester.getRect(find.byType(GlassSheetPage)).top, top);
        }
        await g.up();
        await tester.pumpAndSettle();
        expect(_asked, 0);
        expect(find.text("Sheet"), findsOneWidget);
        expect(tester.getRect(find.byType(GlassSheetPage)).top, top);
        expect(_gestureStuck(tester), isFalse);
      });
    }

    testWidgets("asks nothing while ask is false", (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      var asked = 0;
      showGlassSheet<void>(
        context: _page,
        builder: (_) => GlassSheetConfirmDismiss(
          ask: false,
          confirm: () async {
            asked++;
            return false;
          },
          child: const GlassSheetPage(title: "Sheet", child: Text("body")),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(IrmaCloseButton));
      await tester.pumpAndSettle();
      expect(asked, 0);
      expect(find.text("Sheet"), findsNothing);
    });
    testWidgets("on a tablet, where it is a dialog, it asks too", (
      tester,
    ) async {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(1180, 820);
      addTearDown(() => view.physicalSize = const Size(400, 800));
      await open(tester, answer: false);
      await tester.tap(find.byType(IrmaCloseButton));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(_asked, 2);
      expect(find.text("Sheet"), findsOneWidget);
    });
  });

  testWidgets("content can hide the sheet's rim while it is there", (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    late StateSetter set;
    var dark = true;
    showGlassSheet<void>(
      context: _page,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          set = setState;
          return dark
              ? const GlassSheetNoRim(child: Text("camera"))
              : const Text("light");
        },
      ),
    );
    await tester.pumpAndSettle();
    bool rim() =>
        tester.widget<GlassSurface>(find.byKey(const Key("glass_sheet"))).rim;
    expect(rim(), isFalse);
    set(() => dark = false);
    await tester.pumpAndSettle();
    expect(rim(), isTrue);
  });

  group("pages in the sheet", () {
    /// A sheet with a second page that [push] adds.
    late StateSetter push;
    var pages = 1;
    void openPages() {
      pages = 1;
      showGlassSheet<void>(
        context: _page,
        builder: (_) => StatefulBuilder(
          builder: (context, setState) {
            push = setState;
            return GlassSheetPages(
              onBack: () => setState(() => pages = 1),
              pages: [
                const GlassSheetPage(
                  key: ValueKey("one"),
                  title: "First",
                  child: Text("first page"),
                ),
                if (pages > 1)
                  GlassSheetPage(
                    key: const ValueKey("two"),
                    title: "Second",
                    onBack: () => setState(() => pages = 1),
                    child: const Text("second page"),
                  ),
              ],
            );
          },
        ),
      );
    }

    testWidgets("a new page is a route of its own, named by its title", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      openPages();
      await tester.pumpAndSettle();
      push(() => pages = 2);
      await tester.pumpAndSettle();
      final title = tester.getSemantics(find.text("Second"));
      expect(title.flagsCollection.namesRoute, isTrue);
      expect(title.flagsCollection.isHeader, isTrue);
      var node = title.parent;
      while (node != null && !node.flagsCollection.scopesRoute) {
        node = node.parent;
      }
      expect(node, isNotNull, reason: "the page scopes a route");
      semantics.dispose();
    });

    testWidgets("only the body slides; the bar stays and the titles fade", (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      openPages();
      await tester.pumpAndSettle();
      push(() => pages = 2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final titleMid = tester.getRect(find.text("Second"));
      final bodyMid = tester.getTopLeft(find.text("second page"));
      final fades = tester.widgetList<FadeTransition>(
        find.ancestor(
          of: find.text("Second"),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fades.any((f) => f.opacity.value < 1), isTrue);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text("Second")), titleMid);
      expect(
        tester.getTopLeft(find.text("second page")).dx,
        lessThan(bodyMid.dx),
      );
    });

    testWidgets("what only one bar has fades, the old before the new", (
      tester,
    ) async {
      late StateSetter setPages;
      var two = false;
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      showGlassSheet<void>(
        context: _page,
        builder: (_) => StatefulBuilder(
          builder: (context, setState) {
            setPages = setState;
            return GlassSheetPages(
              onBack: () => setState(() => two = false),
              pages: [
                // A field in the title's place, no back button.
                const GlassSheetPage(
                  key: ValueKey("one"),
                  title: "First",
                  titleWidget: Text("field"),
                  child: Text("first page"),
                ),
                if (two)
                  GlassSheetPage(
                    key: const ValueKey("two"),
                    title: "Second",
                    onBack: () => setState(() => two = false),
                    pinned: const Text("progress"),
                    child: const Text("second page"),
                  ),
              ],
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      /// How visible [finder] is: its fades multiplied.
      double shown(Finder finder) => tester
          .widgetList<FadeTransition>(
            find.ancestor(of: finder, matching: find.byType(FadeTransition)),
          )
          .fold(1.0, (o, f) => o * f.opacity.value);
      final back = find.byKey(const Key("irma_app_bar_leading"));

      setPages(() => two = true);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      // Early: the field is going, the new page's parts are not there yet.
      expect(shown(find.text("field")), inExclusiveRange(0, 1));
      expect(shown(find.text("Second")), 0);
      expect(shown(back), 0);
      expect(shown(find.text("progress")), 0);

      await tester.pump(const Duration(milliseconds: 150));
      // Later: the field is gone; the new ones are coming.
      expect(shown(find.text("field")), 0);
      expect(shown(back), greaterThan(0));
      expect(shown(find.text("progress")), greaterThan(0));

      await tester.pumpAndSettle();
      expect(shown(back), 1);
      expect(shown(find.text("progress")), 1);
    });

    testWidgets("with reduced motion the page fades in instead of sliding", (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            disableAnimations: true,
          ),
          child: _app(),
        ),
      );
      await tester.pumpAndSettle();
      openPages();
      await tester.pumpAndSettle();
      push(() => pages = 2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final page = find.text("second page");
      // Not moved sideways: where it ends up, only not fully opaque yet.
      final x = tester.getTopLeft(page).dx;
      final opacity = tester.widget<FadeTransition>(
        find.ancestor(of: page, matching: find.byType(FadeTransition)).first,
      );
      expect(opacity.opacity.value, lessThan(1));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(page).dx, x);
    });
  });

  group("pages stay alive", () {
    late StateSetter push;
    var pages = 1;
    var builds = 0;

    void openPages() {
      pages = 1;
      builds = 0;
      showGlassSheet<void>(
        context: _page,
        builder: (_) => StatefulBuilder(
          builder: (context, setState) {
            push = setState;
            return GlassSheetPages(
              onBack: () => setState(() => pages = 1),
              pages: [
                GlassSheetPage(
                  key: const ValueKey("list"),
                  title: "List",
                  child: Column(
                    children: [
                      const _Counted(),
                      Builder(
                        builder: (context) {
                          // Depends on where its page is, as the progress
                          // bar does.
                          GlassSheetPages.isTopPage(context);
                          builds++;
                          return Column(
                            children: [
                              for (var i = 0; i < 60; i++) Text("row $i"),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (pages > 1)
                  GlassSheetPage(
                    key: const ValueKey("next"),
                    title: "Next",
                    onBack: () => setState(() => pages = 1),
                    child: const Text("next page"),
                  ),
              ],
            );
          },
        ),
      );
    }

    testWidgets("a page under another keeps its state and its scroll", (
      tester,
    ) async {
      _Counted.inits = 0;
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      openPages();
      await tester.pumpAndSettle();
      expect(_Counted.inits, 1);
      final list = find
          .descendant(
            of: find.byType(GlassSheetScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
      final offset = tester.state<ScrollableState>(list).position.pixels;
      expect(offset, greaterThan(0));

      push(() => pages = 2);
      await tester.pumpAndSettle();
      push(() => pages = 1);
      await tester.pumpAndSettle();

      // The same State: not built anew, still scrolled.
      expect(_Counted.inits, 1);
      expect(
        tester
            .state<ScrollableState>(
              find
                  .descendant(
                    of: find.byType(GlassSheetScrollView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            )
            .position
            .pixels,
        offset,
      );
    });

    testWidgets("a slide does not rebuild the pages' bodies", (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      openPages();
      await tester.pumpAndSettle();
      final before = builds;
      push(() => pages = 2);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
      // At most a rebuild or two when the slide starts or ends, not one per
      // frame.
      expect(builds - before, lessThan(4));
    });
  });

  group("the keyboard", () {
    void openWithField() => showGlassSheet<void>(
      context: _page,
      builder: (_) => GlassSheetPage(
        title: "Sheet",
        bottom: const SizedBox(
          key: Key("sheet_buttons"),
          height: 52,
          width: double.infinity,
        ),
        child: Column(
          children: [
            const TextField(key: Key("field")),
            for (var i = 0; i < 30; i++) Text("row $i"),
          ],
        ),
      ),
    );

    testWidgets("the sheet keeps its size and place; its buttons ride up", (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      openWithField();
      await tester.pumpAndSettle();
      final sheet = find.byKey(const Key("glass_sheet"));
      final before = tester.getRect(sheet);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      expect(tester.getRect(sheet), before);
      expect(
        tester.getRect(find.byKey(const Key("sheet_buttons"))).bottom,
        lessThanOrEqualTo(800 - 300),
      );
      // The rows still scroll, above the keyboard.
      expect(find.byType(Scrollable), findsWidgets);
    });

    testWidgets("a page underneath can't hold or take focus", (tester) async {
      late StateSetter push;
      var pages = 1;
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      showGlassSheet<void>(
        context: _page,
        builder: (_) => StatefulBuilder(
          builder: (context, setState) {
            push = setState;
            return GlassSheetPages(
              onBack: () => setState(() => pages = 1),
              pages: [
                const GlassSheetPage(
                  key: ValueKey("code"),
                  title: "Code",
                  child: TextField(key: Key("code_field"), autofocus: true),
                ),
                if (pages > 1)
                  const GlassSheetPage(
                    key: ValueKey("next"),
                    title: "Next",
                    child: Text("no fields here"),
                  ),
              ],
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      bool fieldFocused() => tester
          .widget<EditableText>(find.byType(EditableText, skipOffstage: false))
          .focusNode
          .hasFocus;
      expect(fieldFocused(), isTrue);

      push(() => pages = 2);
      await tester.pumpAndSettle();
      expect(fieldFocused(), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    });
  });
}

/// Counts how often its State is created.
class _Counted extends StatefulWidget {
  const _Counted();

  static var inits = 0;

  @override
  State<_Counted> createState() => _CountedState();
}

class _CountedState extends State<_Counted> {
  @override
  void initState() {
    super.initState();
    _Counted.inits++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 1);
}
