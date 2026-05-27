import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/providers/issue_during_disclosure_provider.dart";

TrustedParty _issuer() => TrustedParty(
  id: "issuer",
  name: const TranslatedValue.empty(),
  url: null,
  parent: null,
  verified: true,
);

CredentialDescriptor _desc(String credentialId) => CredentialDescriptor(
  credentialId: credentialId,
  name: const TranslatedValue.empty(),
  issuer: _issuer(),
  category: null,
  attributes: const [],
  issueURL: null,
);

IssuanceBundle _bundle(List<String> credentialIds) =>
    IssuanceBundle(credentials: credentialIds.map(_desc).toList());

IssuanceStep _step(List<IssuanceBundle> bundles) =>
    IssuanceStep(options: bundles);

void main() {
  group("isBundleFullySatisfied", () {
    test("empty bundle is never satisfied", () {
      final result = IssueDuringDisclosureNotifier.isBundleFullySatisfied(
        _bundle([]),
        {"foo.bar": "anything"},
      );
      expect(result, isFalse);
    });

    test("null or empty issued map is never satisfied", () {
      final bundle = _bundle(["foo.bar"]);
      expect(
        IssueDuringDisclosureNotifier.isBundleFullySatisfied(bundle, null),
        isFalse,
      );
      expect(
        IssueDuringDisclosureNotifier.isBundleFullySatisfied(bundle, const {}),
        isFalse,
      );
    });

    test("returns true when every descriptor is in issued", () {
      final bundle = _bundle(["foo.bar", "baz.qux"]);
      final issued = {"foo.bar": "x", "baz.qux": "y", "unrelated": "z"};
      expect(
        IssueDuringDisclosureNotifier.isBundleFullySatisfied(bundle, issued),
        isTrue,
      );
    });

    test("returns false when any descriptor is missing", () {
      final bundle = _bundle(["foo.bar", "baz.qux"]);
      final issued = {"foo.bar": "x"};
      expect(
        IssueDuringDisclosureNotifier.isBundleFullySatisfied(bundle, issued),
        isFalse,
      );
    });
  });

  group("findCurrentStepIndex", () {
    test("returns 0 when nothing is issued", () {
      final steps = [
        _step([
          _bundle(["a"]),
        ]),
        _step([
          _bundle(["b"]),
        ]),
      ];
      expect(
        IssueDuringDisclosureNotifier.findCurrentStepIndex(steps, const [
          0,
          0,
        ], null),
        0,
      );
    });

    test("skips fully-satisfied steps for the selected bundle", () {
      final steps = [
        _step([
          _bundle(["a"]),
        ]),
        _step([
          _bundle(["b"]),
        ]),
      ];
      expect(
        IssueDuringDisclosureNotifier.findCurrentStepIndex(
          steps,
          const [0, 0],
          {"a": "issued"},
        ),
        1,
      );
    });

    test("returns null when all selected bundles are satisfied", () {
      final steps = [
        _step([
          _bundle(["a"]),
        ]),
        _step([
          _bundle(["b"]),
        ]),
      ];
      expect(
        IssueDuringDisclosureNotifier.findCurrentStepIndex(
          steps,
          const [0, 0],
          {"a": "x", "b": "y"},
        ),
        null,
      );
    });

    test(
      "respects user selection: returns the step when the user-chosen bundle "
      "is unsatisfied, even if another bundle in the step is satisfied",
      () {
        // Two bundles: A = ["x"], B = ["y"]. "x" is issued; user selected B.
        // The step should still be open because B is not yet satisfied.
        final steps = [
          _step([
            _bundle(["x"]),
            _bundle(["y"]),
          ]),
        ];
        expect(
          IssueDuringDisclosureNotifier.findCurrentStepIndex(
            steps,
            const [1],
            {"x": "issued"},
          ),
          0,
        );
      },
    );

    test("respects user selection when bundle B is satisfied", () {
      final steps = [
        _step([
          _bundle(["x"]),
          _bundle(["y"]),
        ]),
      ];
      // User picked B and B is satisfied — step is done.
      expect(
        IssueDuringDisclosureNotifier.findCurrentStepIndex(
          steps,
          const [1],
          {"y": "issued"},
        ),
        null,
      );
    });

    test("multi-credential bundle requires all descriptors to be issued", () {
      final steps = [
        _step([
          _bundle(["a", "b"]),
        ]),
      ];
      // Only "a" issued — still open.
      expect(
        IssueDuringDisclosureNotifier.findCurrentStepIndex(
          steps,
          const [0],
          {"a": "issued"},
        ),
        0,
      );
      // Both issued — closed.
      expect(
        IssueDuringDisclosureNotifier.findCurrentStepIndex(
          steps,
          const [0],
          {"a": "x", "b": "y"},
        ),
        null,
      );
    });

    test("out-of-range selection is clamped to 0", () {
      final steps = [
        _step([
          _bundle(["a"]),
          _bundle(["b"]),
        ]),
      ];
      // selections[0] = 99 — should be treated as 0 and check bundle A.
      expect(
        IssueDuringDisclosureNotifier.findCurrentStepIndex(
          steps,
          const [99],
          {"a": "issued"},
        ),
        null,
      );
    });
  });

  group("IssuanceStep contract", () {
    test("rejects empty options at the boundary", () {
      // Empty options would cause a RangeError when call sites index
      // steps[currentStepIndex].options[selectedIndex]. We catch this at
      // the deserialization boundary instead, so a malformed backend
      // response is surfaced clearly rather than crashing the UI.
      expect(() => _step(const []), throwsArgumentError);
    });
  });
}
