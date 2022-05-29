import 'package:irmamobile/src/screens/session/disclosure/models/choosable_disclosure_credential.dart';
import 'package:irmamobile/src/screens/session/disclosure/models/disclosure_credential.dart';
import 'package:irmamobile/src/screens/session/disclosure/models/template_disclosure_credential.dart';

import '../../../../models/attributes.dart';

/// Wrapper class to store disconIndex and the current selected conIndex of a particular DisCon.
class DisclosureDisCon {
  final DisCon<DisclosureCredential> _wrapped;

  /// Index of the wrapped DisCon within the disclosure candidates ConDisCon.
  final int disconIndex;

  /// Index of the Con within this DisCon that is currently selected.
  final int selectedConIndex;

  DisclosureDisCon({
    required DisCon<DisclosureCredential> discon,
    required this.disconIndex,
    this.selectedConIndex = 0,
  })  : assert(discon.isNotEmpty),
        assert(disconIndex >= 0),
        _wrapped = discon;

  /// Returns a map with all con indices that are choosable and the corresponding Cons as map value.
  Map<int, Con<ChoosableDisclosureCredential>> get choosableCons => {
        for (int i = 0; i < _wrapped.length; i++)
          if (_wrapped[i].every((cred) => cred is ChoosableDisclosureCredential))
            i: Con(_wrapped[i].whereType<ChoosableDisclosureCredential>())
      };

  /// All template cons within this discon. This also includes choices with combinations of
  /// ChoosableDisclosureCredential and TemplateDisclosureCredentials.
  Map<int, Con<DisclosureCredential>> get templateCons => {
        for (int i = 0; i < _wrapped.length; i++)
          if (_wrapped[i].any((cred) => cred is TemplateDisclosureCredential)) i: _wrapped[i]
      };

  /// The con that is currently selected.
  Con<DisclosureCredential> get selectedCon => _wrapped[selectedConIndex];

  /// Returns whether the current selected discon is fully choosable.
  bool get isSelectedChoosable => choosableCons.containsKey(selectedConIndex);

  /// Returns whether this DisclosureChoice is optional.
  bool get isOptional => choosableCons.values.any((con) => con.isEmpty);

  /// Returns which credential types are involved in this choice.
  /// TODO: is this still necessary?
  // Set<CredentialType> get credentialTypesIncluded =>
  //     _wrapped.fold({}, (prev, con) => {...prev, ...con.map((cred) => cred.credentialType)});

  /// Returns which credential types are involved in a TemplateDisclosureCredential within this choice.
  /// TODO: remove?
  // Set<CredentialType> get credentialTypesIncludedInTemplate => templateCons.fold(
  //       {},
  //       (prev, con) => {
  //         ...prev,
  //         ...con.whereType<TemplateDisclosureCredential>().map((cred) => cred.credentialType),
  //       },
  //     );

  DisclosureDisCon copyWith({required int selectedConIndex}) => DisclosureDisCon(
        discon: _wrapped,
        disconIndex: disconIndex,
        selectedConIndex: selectedConIndex,
      );
}
