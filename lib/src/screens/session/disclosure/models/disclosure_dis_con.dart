import 'package:collection/collection.dart';
import 'package:irmamobile/src/screens/session/disclosure/models/choosable_disclosure_credential.dart';
import 'package:irmamobile/src/screens/session/disclosure/models/disclosure_credential.dart';
import 'package:irmamobile/src/screens/session/disclosure/models/template_disclosure_credential.dart';

import '../../../../models/irma_configuration.dart';
import 'disclosure_con.dart';

/// Wrapper class to store disconIndex and the current selected conIndex of a particular DisCon.
class DisclosureDisCon extends Iterable<DisclosureCon> {
  final List<DisclosureCon> _wrapped;

  /// Index of the wrapped DisCon within the disclosure candidates ConDisCon.
  final int disconIndex;

  /// All choosable cons within this choice.
  Iterable<DisclosureCon<ChoosableDisclosureCredential>> get choosableCons =>
      _wrapped.map((con) => con.asChoosable()).whereNotNull();

  /// All template cons within this discon. This also includes choices with combinations of
  /// ChoosableDisclosureCredential and TemplateDisclosureCredentials.
  Iterable<DisclosureCon> get templateCons => _wrapped.where((con) => con.needsToBeObtained);

  /// The con that is currently selected.
  DisclosureCon get selectedCon => _wrapped.firstWhere((con) => con.selected);

  /// Returns whether this DisclosureChoice is optional.
  bool get isOptional => choosableCons.any((con) => con.isEmpty);

  /// Returns which credential types are involved in this choice.
  Set<CredentialType> get credentialTypesIncluded =>
      _wrapped.fold({}, (prev, con) => {...prev, ...con.map((cred) => cred.credentialType)});

  /// Returns which credential types are involved in a TemplateDisclosureCredential within this choice.
  Set<CredentialType> get credentialTypesIncludedInTemplate => templateCons.fold(
        {},
        (prev, con) => {
          ...prev,
          ...con.whereType<TemplateDisclosureCredential>().map((cred) => cred.credentialType),
        },
      );

  DisclosureDisCon({
    required List<DisclosureCon> discon,
    required this.disconIndex,
  })  : assert(disconIndex >= 0),
        // Ensure that all con indices are unique.
        assert(discon
            .map((con) => con.conIndices)
            .flattened
            .groupListsBy((i) => i)
            .values
            .every((indices) => indices.length == 1)),
        // Ensure that only one con is selected.
        assert(discon.singleWhereOrNull((con) => con.selected) != null),
        _wrapped = discon;

  DisclosureDisCon copyWith({required int selectedConIndex}) => DisclosureDisCon(
        discon: _wrapped
            .map((con) => con.copyWith(
                  selected: con.conIndices.contains(selectedConIndex),
                ))
            .toList(),
        disconIndex: disconIndex,
      );

  /// Returns the DisclosureCon with the given conIndex (if present).
  DisclosureCon? operator [](int conIndex) => _wrapped.firstWhereOrNull((con) => con.conIndices.contains(conIndex));

  @override
  Iterator<DisclosureCon<DisclosureCredential>> get iterator => _wrapped.iterator;
}
