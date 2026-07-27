import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/providers/store_review_provider.dart";

void main() {
  const day = Duration(days: 1);
  const ninetyDays = reviewReAskDelay;

  group("shouldAskForReview", () {
    test("first ask fires exactly at the threshold", () {
      expect(
        shouldAskForReview(
          done: false,
          timesAsked: 0,
          successCount: reviewFirstAskThreshold - 1,
          lastAskEpochMs: 0,
          nowEpochMs: 0,
        ),
        isFalse,
      );
      expect(
        shouldAskForReview(
          done: false,
          timesAsked: 0,
          successCount: reviewFirstAskThreshold,
          lastAskEpochMs: 0,
          nowEpochMs: 0,
        ),
        isTrue,
      );
    });

    test("done is terminal regardless of counts", () {
      expect(
        shouldAskForReview(
          done: true,
          timesAsked: 0,
          successCount: 999,
          lastAskEpochMs: 0,
          nowEpochMs: 0,
        ),
        isFalse,
      );
    });

    test("second ask needs both the higher count and the delay", () {
      final lastAsk = day.inMilliseconds;
      // Enough sessions but not enough time passed.
      expect(
        shouldAskForReview(
          done: false,
          timesAsked: 1,
          successCount: reviewSecondAskThreshold,
          lastAskEpochMs: lastAsk,
          nowEpochMs: lastAsk + ninetyDays.inMilliseconds - 1,
        ),
        isFalse,
      );
      // Enough time but not enough sessions.
      expect(
        shouldAskForReview(
          done: false,
          timesAsked: 1,
          successCount: reviewSecondAskThreshold - 1,
          lastAskEpochMs: lastAsk,
          nowEpochMs: lastAsk + ninetyDays.inMilliseconds,
        ),
        isFalse,
      );
      // Both satisfied.
      expect(
        shouldAskForReview(
          done: false,
          timesAsked: 1,
          successCount: reviewSecondAskThreshold,
          lastAskEpochMs: lastAsk,
          nowEpochMs: lastAsk + ninetyDays.inMilliseconds,
        ),
        isTrue,
      );
    });

    test("never asks a third time", () {
      expect(
        shouldAskForReview(
          done: false,
          timesAsked: 2,
          successCount: 999,
          lastAskEpochMs: 0,
          nowEpochMs: 999 * ninetyDays.inMilliseconds,
        ),
        isFalse,
      );
    });
  });
}
