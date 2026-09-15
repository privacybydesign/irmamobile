import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../irma_binding.dart";
import "special_scenarios/decline_disclosure.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("mdoc-disclosure-sessions", () {
    setUp(() async => await irmaBinding.setUp());
    tearDown(() async => await irmaBinding.tearDown());

    group("special-scenarios", () {
      // User declines at the share dialog; nothing logged, nothing posted.
      testWidgets(
        "decline-disclosure",
        (tester) => declineDisclosureTest(tester, irmaBinding),
      );
    });
  });
}
