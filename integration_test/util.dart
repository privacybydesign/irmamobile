import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterUtil on WidgetTester {
  /// Renders the given widget and waits until it settles.
  Future<void> pumpWidgetAndSettle(Widget w) async {
    await pumpWidget(w, const Duration(seconds: 2));
    await waitFor(find.byWidget(w));
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

  /// Waits for the given widget to disappear. When the timeout passes, an exception is given.
  Future<void> waitUntilDisappeared(Finder f, {Duration timeout = const Duration(minutes: 1)}) =>
      Future.doWhile(() async {
        await pumpAndSettle();
        return any(f);
      }).timeout(timeout);

  /// Returns the data strings of all populated Text widgets being descendant of the given widget. If the
  /// given widget is a Text widget itself, it only returns the data string of that Text widget.
  Iterable<String> getAllText(Finder f) =>
      widgetList(find.descendant(of: f, matching: find.byType(Text), matchRoot: true))
          .cast<Text>()
          .where((w) => w.data != null)
          .map((w) => w.data!);
}
