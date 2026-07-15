import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // StreamingSharedPreferences.instance is a process-wide singleton, so
  // setMockInitialValues alone does not reset values between tests. clearAll()
  // wipes the backing store, giving each test a clean slate.
  Future<IrmaPreferences> freshPrefs() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await prefs.clearAll();
    return prefs;
  }

  test("review state starts at zero", () async {
    final prefs = await freshPrefs();
    expect(prefs.getReviewSuccessCountNow(), 0);
    expect(prefs.getReviewTimesAskedNow(), 0);
    expect(prefs.getReviewLastAskEpochMsNow(), 0);
    expect(prefs.getReviewDoneNow(), isFalse);
  });

  test("incrementReviewSuccessCount adds one each call", () async {
    final prefs = await freshPrefs();
    await prefs.incrementReviewSuccessCount();
    await prefs.incrementReviewSuccessCount();
    expect(prefs.getReviewSuccessCountNow(), 2);
  });

  test("recordReviewAsked bumps the ask count and stamps the time", () async {
    final prefs = await freshPrefs();
    await prefs.recordReviewAsked(nowEpochMs: 1234);

    expect(prefs.getReviewTimesAskedNow(), 1);
    expect(prefs.getReviewLastAskEpochMsNow(), 1234);

    await prefs.recordReviewAsked(nowEpochMs: 5678);
    expect(prefs.getReviewTimesAskedNow(), 2);
    expect(prefs.getReviewLastAskEpochMsNow(), 5678);
  });

  test("setReviewDone persists", () async {
    final prefs = await freshPrefs();
    await prefs.setReviewDone(true);
    expect(prefs.getReviewDoneNow(), isTrue);
  });
}
