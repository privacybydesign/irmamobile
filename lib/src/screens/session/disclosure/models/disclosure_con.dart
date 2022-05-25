import 'package:collection/collection.dart';
import 'package:irmamobile/src/screens/session/disclosure/models/choosable_disclosure_credential.dart';

import '../../../../models/attributes.dart';
import 'disclosure_credential.dart';
import 'template_disclosure_credential.dart';

/// Wrapper class to store conIndices and the 'selected' flag of a particular Con.
class DisclosureCon<T extends DisclosureCredential> extends Iterable<T> {
  final Con<T> _wrapped;

  /// Indices of all occurrences of this con in the parent discon.
  final UnmodifiableSetView<int> conIndices;

  /// Returns whether this option is currently selected.
  final bool selected;

  /// Returns whether the Con contains template credentials that need to be obtained first.
  bool get needsToBeObtained => any((cred) => cred is TemplateDisclosureCredential);

  /// Only returns the TemplateDisclosureCredentials in this con.
  Iterable<TemplateDisclosureCredential> get templates => whereType<TemplateDisclosureCredential>();

  DisclosureCon({
    required Con<T> con,
    required Set<int> conIndices,
    this.selected = false,
  })  : assert(conIndices.every((index) => index >= 0)),
        conIndices = UnmodifiableSetView(conIndices),
        _wrapped = con;

  DisclosureCon copyWith({bool? selected}) => DisclosureCon(
        con: _wrapped,
        conIndices: conIndices,
        selected: selected ?? this.selected,
      );

  /// Returns a new DisclosureChoiceOption with the merged contents of this and the given other DisclosureChoiceOption,
  /// if they don't contradict. Returns null otherwise.
  DisclosureCon? copyAndMerge(DisclosureCon other) {
    if (length != other.length) return null;
    // If two credentials having type T are merged, the result will also have type T. Therefore, we can safely cast.
    final mergedCons = map(
        (cred) => other.fold<DisclosureCredential?>(null, (prev, otherCred) => prev ?? cred.copyAndMerge(otherCred)));
    if (mergedCons.contains(null)) return null;

    return DisclosureCon(
      con: Con(mergedCons.whereNotNull()),
      conIndices: {...conIndices, ...other.conIndices},
    );
  }

  /// Converts this DisclosureCon to a instance that only wraps ChoosableDisclosureCredentials.
  /// If this DisclosureCon does not exclusively contain ChoosableDisclosureCredentials, then null is returned.
  DisclosureCon<ChoosableDisclosureCredential>? asChoosable() => needsToBeObtained
      ? null
      : DisclosureCon(
          con: Con(_wrapped.whereType<ChoosableDisclosureCredential>()),
          conIndices: conIndices,
          selected: selected,
        );

  /// Returns the DisclosureCredential with the given index (if present).
  T operator [](int i) => _wrapped[i];

  @override
  Iterator<T> get iterator => _wrapped.iterator;
}
