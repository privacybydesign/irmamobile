import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../irma_binding.dart";
import "scenarios/combination_two_kinds_pick_per_card.dart";
import "scenarios/finish_an_option.dart";
import "scenarios/identical_cards_merged.dart";
import "scenarios/multiple_pick_several.dart";
import "scenarios/one_of_several_values.dart";
import "scenarios/optional_big_choice.dart";
import "scenarios/options_with_several_cards.dart";
import "scenarios/query_in_two_sets.dart";
import "scenarios/same_kind_twice.dart";
import "scenarios/signing_complex.dart";
import "scenarios/two_sets_stress.dart";

/// The complex disclosure cases: choices of several cards, optional sets,
/// several values, one query in two sets (build plan 6.3).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("complex-disclosure-sessions", () {
    setUp(() async => await irmaBinding.setUp());
    tearDown(() async => await irmaBinding.tearDown());

    testWidgets(
      "combination-two-kinds-pick-per-card",
      (tester) => combinationTwoKindsPickPerCardTest(tester, irmaBinding),
    );
    testWidgets(
      "options-with-several-cards",
      (tester) => optionsWithSeveralCardsTest(tester, irmaBinding),
    );
    testWidgets(
      "finish-an-option",
      (tester) => finishAnOptionTest(tester, irmaBinding),
    );
    testWidgets(
      "two-sets-stress",
      (tester) => twoSetsStressTest(tester, irmaBinding),
    );
    testWidgets(
      "two-sets-second-optional",
      (tester) => twoSetsStressTest(tester, irmaBinding, secondOptional: true),
    );
    testWidgets(
      "same-kind-twice",
      (tester) => sameKindTwiceTest(tester, irmaBinding),
    );
    testWidgets(
      "multiple-pick-several",
      (tester) => multiplePickSeveralTest(tester, irmaBinding),
    );
    testWidgets(
      "identical-cards-merged",
      (tester) => identicalCardsMergedTest(tester, irmaBinding),
    );
    testWidgets(
      "optional-big-choice",
      (tester) => optionalBigChoiceTest(tester, irmaBinding),
    );
    testWidgets(
      "optional-single-share-too",
      (tester) => optionalSingleShareTooTest(tester, irmaBinding),
    );
    testWidgets(
      "optional-nothing-chosen",
      (tester) => optionalNothingChosenTest(tester, irmaBinding),
    );
    testWidgets(
      "one-of-several-values",
      (tester) => oneOfSeveralValuesTest(tester, irmaBinding),
    );
    testWidgets(
      "one-of-several-values-empty",
      (tester) => oneOfSeveralValuesEmptyTest(tester, irmaBinding),
    );
    testWidgets(
      "query-in-two-sets",
      (tester) => queryInTwoSetsTest(tester, irmaBinding),
    );
    testWidgets(
      "signing-complex",
      (tester) => signingComplexTest(tester, irmaBinding),
    );
  });
}
