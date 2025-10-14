import 'package:flutter/widgets.dart';

/// When this widget is found in the widget tree, we can assume the integration tests are running.
class TestContext extends InheritedWidget {
  const TestContext({super.key, required super.child});

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }

  static bool isRunningIntegrationTest(BuildContext context) {
    return context.findAncestorWidgetOfExactType<TestContext>() != null;
  }
}
