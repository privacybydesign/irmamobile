import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi_core/src/providers/store_review_provider.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";

import "helpers/helpers.dart";
import "helpers/issuance_helpers.dart";
import "irma_binding.dart";
import "util.dart";

/// Stands in for the real in-app-review plugin: the native review sheet can't
/// be shown or asserted in a test, so we only verify that the app asked for it.
class _FakeStoreReviewService implements StoreReviewService {
  int requestReviewCalls = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async => requestReviewCalls++;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("store review", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    // Seed the success count to one below the threshold, then run a single real
    // issuance session so a genuine SessionStatus.success crosses it. On the
    // return to the idle home screen the gate fires the sentiment prompt.
    Future<_FakeStoreReviewService> reachGateAfterOneSession(
      WidgetTester tester,
    ) async {
      final prefs = irmaBinding.repository.preferences;
      for (var i = 0; i < reviewFirstAskThreshold - 1; i++) {
        await prefs.incrementReviewSuccessCount();
      }

      final service = _FakeStoreReviewService();
      await pumpAndUnlockApp(
        tester,
        irmaBinding.repository,
        providerOverrides: [
          storeReviewServiceProvider.overrideWithValue(service),
        ],
      );

      await issueMunicipalityPersonalData(tester, irmaBinding);
      await tester.pumpAndSettle();
      expect(find.byType(IssuanceSuccessScreen), findsOneWidget);
      await tester.tapAndSettle(find.text("OK"));

      await tester.waitFor(find.byKey(const Key("review_gate_positive")));
      return service;
    }

    testWidgets("yes, I like it: routes to the native store review", (
      tester,
    ) async {
      final service = await reachGateAfterOneSession(tester);

      await tester.tapAndSettle(find.byKey(const Key("review_gate_positive")));

      await tester.pumpUntil(() => service.requestReviewCalls == 1);
      expect(irmaBinding.repository.preferences.getReviewDoneNow(), isTrue);
    });

    testWidgets("no, not really: routes to private feedback, not the store", (
      tester,
    ) async {
      final service = await reachGateAfterOneSession(tester);

      await tester.tapAndSettle(find.byKey(const Key("review_gate_negative")));

      await tester.waitFor(find.byKey(const Key("review_feedback_input")));
      expect(service.requestReviewCalls, 0);
      expect(irmaBinding.repository.preferences.getReviewDoneNow(), isTrue);
    });
  });
}
