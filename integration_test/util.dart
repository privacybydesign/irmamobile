import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterUtil on WidgetTester {
  /// Renders the given widget and waits until it settles.
  Future<void> pumpWidgetAndSettle(Widget w) async {
    await pumpWidget(w);
    await waitFor(find.byWidget(w));
  }

  /// Enters the given text in the EditableText that currently is in focus.
  Future<void> enterTextAtFocusedAndSettle(String text) async {
    await enterText(find.byWidgetPredicate((w) => w is EditableText && w.focusNode.hasFocus), text);
    await pumpAndSettle(const Duration(milliseconds: 500));
  }

  /// Taps on the given widget, waits for a response, triggers a new frame sequence
  /// to be rendered (check the description of pump) and waits until the widget settles.
  /// The waiting time can be specified using 'duration'.
  Future<void> tapAndSettle(Finder f, {Duration duration = const Duration(milliseconds: 100)}) async {
    await tap(f);
    await pumpAndSettle(duration);
  }

  /// Waits for the given widget to appear. When the timeout passes, an exception is given.
  Future<void> waitFor(Finder f, {Duration timeout = const Duration(minutes: 1)}) => Future.doWhile(() async {
        await pumpAndSettle();
        return !any(f);
      }).timeout(timeout);

  /// Returns the string being inside the given Text widget.
  /// When 'firstMatchOnly' is true, it also checks descendants of the given widget for text being present.
  /// Only the first match is returned.
  String getText(Finder f, {bool firstMatchOnly = false}) => firstMatchOnly
      ? firstWidget<Text>(find.descendant(of: f, matching: find.byType(Text), matchRoot: true)).data
      : widget<Text>(f).data;

  /// Looks for a Scrollable inside a widget with Key 'parentKey', scrolls through all items
  /// to look for a Text widget with Key 'textKey' and checks whether its value equals to 'textValue'.
  Future<void> scrollAndCheckText(String parentKey, String textKey, String textValue) async {
    final parentWidget = find.byKey(Key(parentKey));
    final textWidget = find.descendant(of: parentWidget, matching: find.byKey(Key(textKey)));
    await scrollUntilVisible(textWidget, 30,
        scrollable: find.descendant(
          of: parentWidget,
          matching: find.byWidgetPredicate((widget) => widget is Scrollable),
          matchRoot: true,
        ));
    final string = getText(textWidget);
    expect(string, textValue);
  }
}
