import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/store_review_provider.dart";
import "package:yivi_core/src/screens/review/store_review_gate_dialog.dart";
import "package:yivi_core/src/theme/theme.dart";

/// Empty translations: this test asserts on widget keys, never on copy, so it
/// sidesteps the FileTranslationLoader's real IO (which doesn't settle under
/// the test's fake clock).
class _NoopTranslationLoader extends TranslationLoader {
  @override
  Future<Map> load() async => <String, dynamic>{};
}

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
    return ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        storeReviewServiceProvider.overrideWithValue(service),
      ],
      child: IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(translationLoader: _NoopTranslationLoader()),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
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
        ),
      ),
    );
  }

  testWidgets("positive answer requests a review and is terminal", (
    tester,
  ) async {
    final prefs = await freshPrefs();
    final service = _FakeStoreReviewService();

    await tester.pumpWidget(host(prefs, service));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key("open")));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("review_gate_positive")), findsOneWidget);

    await tester.tap(find.byKey(const Key("review_gate_positive")));
    await tester.pumpAndSettle();

    expect(service.requestReviewCalls, 1);
    expect(prefs.getReviewDoneNow(), isTrue);
    // Dialog closed.
    expect(find.byKey(const Key("review_gate_positive")), findsNothing);
  });

  testWidgets("negative answer opens the feedback box and is terminal", (
    tester,
  ) async {
    final prefs = await freshPrefs();
    final service = _FakeStoreReviewService();

    await tester.pumpWidget(host(prefs, service));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key("open")));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("review_gate_negative")));
    await tester.pumpAndSettle();

    expect(service.requestReviewCalls, 0);
    expect(prefs.getReviewDoneNow(), isTrue);
    // Routed to the private feedback box, not the store.
    expect(find.byKey(const Key("review_feedback_input")), findsOneWidget);
  });
}
