import "package:flutter/widgets.dart";

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

/// Whether pictures stand still instead of moving: when the user asked for
/// less motion, and in the integration tests, where a looping animation
/// would never let the screen settle.
bool motionStill(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    TestContext.isRunningIntegrationTest(context);
