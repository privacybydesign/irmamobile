import 'package:flutter/material.dart';
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

  /// Returns the data strings of all populated Text widgets being descendant of the given widget. If the
  /// given widget is a Text widget itself, it only returns the data string of that Text widget.
  Iterable<String> getAllText(Finder f) =>
      widgetList(find.descendant(of: f, matching: find.byType(Text), matchRoot: true))
          .cast<Text>()
          .where((w) => w.data != null)
          .map((w) => w.data!);

  /// Returns the switch value of the SwitchListTile that contains the widget being found by the given finder.
  bool getSwitchListTileValue(Finder f) => (widget(find.byWidgetPredicate((widget) =>
          widget is SwitchListTile &&
          any(find.descendant(
            of: find.byWidget(widget),
            matching: f,
          )))) as SwitchListTile)
      .value;

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
    final string = getAllText(textWidget).first;
    expect(string, textValue);
  }

  /// Returns a finder matching all widgets from a given type that contain the given content.
  Finder findByTypeWithContent({required Type type, required Finder content}) => find.byWidgetPredicate(
      (widget) => widget.runtimeType == type && any(find.descendant(of: find.byWidget(widget), matching: content)));
}
