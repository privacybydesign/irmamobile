import "../providers/issue_during_disclosure_provider.dart";
import "schemaless/credential_store.dart";
import "schemaless/session_state.dart";

/// One requested credential in the missing data checklist.
class ChecklistEntry {
  final CredentialDescriptor credential;
  final bool isPresent;

  const ChecklistEntry({required this.credential, required this.isPresent});
}

/// One [IssuanceStep] of the plan, shown as the credentials of a single bundle.
class ChecklistStep {
  final int index;
  final IssuanceStep step;
  final int shownOptionIndex;
  final List<ChecklistEntry> entries;

  const ChecklistStep({
    required this.index,
    required this.step,
    required this.shownOptionIndex,
    required this.entries,
  });

  bool get isPresent => entries.every((e) => e.isPresent);

  /// A step the user can still satisfy in more than one way.
  bool get isChoice => step.options.length > 1 && !isPresent;
}

/// The requested credentials that were missing when the session started, and
/// which of them are in the app by now.
///
/// irmago only plans the requests the app could not satisfy, so credentials
/// the user already had before the session are not part of this list.
class MissingDataChecklist {
  final List<ChecklistStep> steps;

  const MissingDataChecklist(this.steps);

  factory MissingDataChecklist.fromWizardState(IssueDuringDisclosureState s) {
    return MissingDataChecklist([
      for (var i = 0; i < s.steps.length; i++)
        _buildStep(
          i,
          s.steps[i],
          i < s.selectedOptionPerStep.length ? s.selectedOptionPerStep[i] : 0,
          s.issuedCredentialIds,
        ),
    ]);
  }

  List<ChecklistEntry> get entries => [for (final s in steps) ...s.entries];

  int get total => entries.length;

  int get presentCount => entries.where((e) => e.isPresent).length;

  int get missingCount => total - presentCount;

  bool get isComplete => total > 0 && missingCount == 0;

  /// The first missing credential the user can obtain in the app, with the
  /// step it belongs to.
  ({ChecklistStep step, ChecklistEntry entry})? get next {
    for (final step in steps) {
      for (final entry in step.entries) {
        if (!entry.isPresent && entry.credential.issueURL != null) {
          return (step: step, entry: entry);
        }
      }
    }
    return null;
  }

  static ChecklistStep _buildStep(
    int index,
    IssuanceStep step,
    int selectedOption,
    Set<String> issued,
  ) {
    bool isSatisfied(IssuanceBundle b) =>
        b.credentials.isNotEmpty &&
        b.credentials.every((c) => issued.contains(c.credentialId));

    final selected = selectedOption >= 0 && selectedOption < step.options.length
        ? selectedOption
        : 0;
    // The plan is satisfied by any option, so show the one that was obtained
    // over the one that was merely selected.
    final shown = isSatisfied(step.options[selected])
        ? selected
        : step.options.indexWhere(isSatisfied);
    final shownIndex = shown >= 0 ? shown : selected;

    return ChecklistStep(
      index: index,
      step: step,
      shownOptionIndex: shownIndex,
      entries: [
        for (final c in step.options[shownIndex].credentials)
          ChecklistEntry(
            credential: c,
            isPresent: issued.contains(c.credentialId),
          ),
      ],
    );
  }
}
