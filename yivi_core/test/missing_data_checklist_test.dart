import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/missing_data_checklist.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/providers/issue_during_disclosure_provider.dart";

import "missing_data_fixtures.dart";

IssueDuringDisclosureState _wizard(
  List<IssuanceStep> steps, {
  Set<String> issued = const {},
  List<int>? selections,
}) => IssueDuringDisclosureState(
  steps: steps,
  selectedOptionPerStep: selections ?? List.filled(steps.length, 0),
  issuedCredentialIds: issued,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("MissingDataChecklist", () {
    final email = testDescriptor("email");
    final phone = testDescriptor("phone");

    test("counts the credentials of every step", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard([
          testStep([
            [email],
          ]),
          testStep([
            [phone],
          ]),
        ]),
      );

      expect(checklist.total, 2);
      expect(checklist.presentCount, 0);
      expect(checklist.missingCount, 2);
      expect(checklist.isComplete, isFalse);
    });

    test("marks issued credentials as present and moves next", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard(
          [
            testStep([
              [email],
            ]),
            testStep([
              [phone],
            ]),
          ],
          issued: {"email"},
        ),
      );

      expect(checklist.presentCount, 1);
      expect(checklist.next?.entry.credential.credentialId, "phone");
      expect(checklist.next?.step.index, 1);
    });

    test("is complete when every credential is issued", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard(
          [
            testStep([
              [email],
            ]),
          ],
          issued: {"email"},
        ),
      );

      expect(checklist.isComplete, isTrue);
      expect(checklist.next, isNull);
    });

    test("next skips credentials that cannot be obtained in the app", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard([
          testStep([
            [testDescriptor("elsewhere", issueURL: null)],
          ]),
          testStep([
            [phone],
          ]),
        ]),
      );

      expect(checklist.next?.entry.credential.credentialId, "phone");
    });

    test("a multi-credential bundle counts every credential", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard(
          [
            testStep([
              [email, phone],
            ]),
          ],
          issued: {"email"},
        ),
      );

      expect(checklist.total, 2);
      expect(checklist.presentCount, 1);
      expect(checklist.steps.single.isPresent, isFalse);
    });

    test("a step with options is a choice until one option is obtained", () {
      final steps = [
        testStep([
          [email],
          [phone],
        ]),
      ];

      final open = MissingDataChecklist.fromWizardState(_wizard(steps));
      expect(open.steps.single.isChoice, isTrue);
      expect(open.total, 1);

      final done = MissingDataChecklist.fromWizardState(
        _wizard(steps, issued: {"phone"}),
      );
      expect(done.steps.single.isChoice, isFalse);
      expect(done.steps.single.entries.single.credential.credentialId, "phone");
      expect(done.isComplete, isTrue);
    });

    test("follows the selected option while none is obtained", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard(
          [
            testStep([
              [email],
              [phone],
            ]),
          ],
          selections: [1],
        ),
      );

      expect(checklist.steps.single.shownOptionIndex, 1);
      expect(
        checklist.steps.single.entries.single.credential.credentialId,
        "phone",
      );
    });

    test("ignores a selection outside the options", () {
      final checklist = MissingDataChecklist.fromWizardState(
        _wizard(
          [
            testStep([
              [email],
            ]),
          ],
          selections: [5],
        ),
      );

      expect(checklist.steps.single.shownOptionIndex, 0);
    });
  });
}
