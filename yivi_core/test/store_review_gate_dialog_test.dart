import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/store_review_provider.dart";
import "package:yivi_core/src/screens/review/store_review_gate_dialog.dart";

import "support/pump_translated.dart";
import "support/test_app.dart";

class _FakeStoreReviewService implements StoreReviewService {
  int requestReviewCalls = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async => requestReviewCalls++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<IrmaPreferences> freshPrefs() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
    return prefs;
  }

  Widget host(IrmaPreferences prefs, StoreReviewService service) {
    return testApp(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key("open"),
              onPressed: () => showStoreReviewGateDialog(context),
              child: const Text("open"),
            ),
          ),
        ),
      ),
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        storeReviewServiceProvider.overrideWithValue(service),
      ],
    );
  }

  testWidgets("positive answer requests a review and is terminal", (
    tester,
  ) async {
    final prefs = await freshPrefs();
    final service = _FakeStoreReviewService();

    await pumpTranslated(tester, host(prefs, service));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key("open")));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("review_gate_positive")), findsOneWidget);

    await tester.tap(find.byKey(const Key("review_gate_positive")));
    await tester.pumpAndSettle();

    expect(service.requestReviewCalls, 1);
    expect(prefs.reviewDone.value, isTrue);
    // Dialog closed.
    expect(find.byKey(const Key("review_gate_positive")), findsNothing);
  });

  testWidgets("negative answer opens the feedback box and is terminal", (
    tester,
  ) async {
    final prefs = await freshPrefs();
    final service = _FakeStoreReviewService();

    await pumpTranslated(tester, host(prefs, service));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key("open")));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("review_gate_negative")));
    await tester.pumpAndSettle();

    expect(service.requestReviewCalls, 0);
    expect(prefs.reviewDone.value, isTrue);
    // Routed to the private feedback box, not the store.
    expect(find.byKey(const Key("review_feedback_input")), findsOneWidget);
  });
}
