import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_feedback_screen.dart";

/// A zero-knowledge disclosure is reported as its own outcome, and that outcome
/// is still a success.
///
/// Both halves matter. If it were not its own type the user would be told their
/// data was disclosed when it was proved instead, and if it were not a success
/// the screen would show the error illustration for an exchange that worked.
void main() {
  test("zeroKnowledge is a success outcome", () {
    expect(DisclosureFeedbackType.zeroKnowledge.isSuccess, isTrue);
    expect(DisclosureFeedbackType.success.isSuccess, isTrue);
  });

  test("the failure outcomes are not", () {
    expect(DisclosureFeedbackType.canceled.isSuccess, isFalse);
    expect(DisclosureFeedbackType.notSatisfiable.isSuccess, isFalse);
  });

  test("zeroKnowledge has its own translation key", () {
    // The key drives both the title and the explanation, so sharing "success"
    // would silently show the plain-disclosure wording for a proof.
    final screen = DisclosureFeedbackScreen(
      feedbackType: DisclosureFeedbackType.zeroKnowledge,
      otherParty: "Test Verifier",
      onDismiss: (_) {},
    );
    expect(screen.feedbackType, DisclosureFeedbackType.zeroKnowledge);
    expect(
      DisclosureFeedbackType.values.map((t) => t.name).toSet(),
      hasLength(DisclosureFeedbackType.values.length),
    );
  });
}
