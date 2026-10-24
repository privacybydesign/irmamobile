// The tabs of the home screen: kept as they were when the user comes back,
// and, as on iOS, back to the top on a tap on the selected tab or on the
// status bar.

import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/more/more_tab.dart";

import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();

  group("home-tabs", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("a tab is kept as it was left", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      final data = tester.state(find.byType(DataTab));

      await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
      final more = tester.state(find.byType(MoreTab));
      final scroll = _moreScroll(tester);
      scroll.jumpTo(scroll.maxScrollExtent);
      await tester.pumpAndSettle();
      final scrolled = scroll.pixels;
      expect(scrolled, greaterThan(0));

      await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
      expect(tester.state(find.byType(DataTab)), same(data));

      // Back on More: the same tab, still scrolled.
      await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
      expect(tester.state(find.byType(MoreTab)), same(more));
      expect(_moreScroll(tester).pixels, scrolled);
    });

    testWidgets("a tap on the selected tab scrolls it to the top", (
      tester,
    ) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
      final scroll = _moreScroll(tester);
      scroll.jumpTo(scroll.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(scroll.pixels, greaterThan(0));

      await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
      expect(_moreScroll(tester).pixels, _moreScroll(tester).minScrollExtent);
    });

    testWidgets("a tap on the status bar scrolls the list to the top", (
      tester,
    ) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await tester.tapAndSettle(find.byKey(const Key("nav_button_more")));
      final scroll = _moreScroll(tester);
      scroll.jumpTo(scroll.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(scroll.pixels, greaterThan(0));

      // As the iOS engine sends a tap on the status bar: a message, not a
      // touch.
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.statusBar.name,
        SystemChannels.statusBar.codec.encodeMethodCall(
          const MethodCall("handleScrollToTop"),
        ),
        (_) {},
      );
      await tester.pumpAndSettle();
      expect(_moreScroll(tester).pixels, _moreScroll(tester).minScrollExtent);
    });
  });
}

/// The More tab's list.
ScrollPosition _moreScroll(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(MoreTab),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;
