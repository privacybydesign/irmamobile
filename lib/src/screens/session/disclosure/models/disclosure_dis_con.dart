import 'package:irmamobile/src/screens/session/disclosure/models/choosable_disclosure_credential.dart';
import 'package:irmamobile/src/screens/session/disclosure/models/disclosure_credential.dart';
import 'package:irmamobile/src/screens/session/disclosure/models/template_disclosure_credential.dart';

import '../../../../models/attributes.dart';

/// Wrapper class to store disconIndex and the current selected conIndex of a particular DisCon.
class DisclosureDisCon {
  final DisCon<DisclosureCredential> discon;

  /// Index of the wrapped DisCon within the disclosure candidates ConDisCon.
  final int disconIndex;

  /// Index of the Con within this DisCon that is currently selected.
  final int selectedConIndex;

  DisclosureDisCon({
    required this.discon,
    required this.disconIndex,
    this.selectedConIndex = 0,
  })  : assert(discon.isNotEmpty),
        assert(disconIndex >= 0);

  /// Returns a map with all con indices that are choosable and the corresponding Cons as map value.
  Map<int, Con<ChoosableDisclosureCredential>> get choosableCons => {
        for (int i = 0; i < discon.length; i++)
          if (discon[i].every((cred) => cred is ChoosableDisclosureCredential))
            i: Con(discon[i].whereType<ChoosableDisclosureCredential>())
      };

  /// All template cons within this discon. This also includes choices with combinations of
  /// ChoosableDisclosureCredential and TemplateDisclosureCredentials.
  Map<int, Con<DisclosureCredential>> get templateCons => {
        for (int i = 0; i < discon.length; i++)
          if (discon[i].any((cred) => cred is TemplateDisclosureCredential)) i: discon[i]
      };

  /// The con that is currently selected.
  Con<DisclosureCredential> get selectedCon => discon[selectedConIndex];

  /// Returns whether the current selected discon is fully choosable.
  bool get isSelectedChoosable => choosableCons.containsKey(selectedConIndex);

  /// Returns whether this DisclosureChoice is optional.
  bool get isOptional => choosableCons.values.any((con) => con.isEmpty);

  /// Returns whether the given DisclosureCredential is involved in this DisCon.
  bool contains(DisclosureCredential credential) => discon.any((con) => con.any((cred) => cred == credential));

  DisclosureDisCon copyWith({required int selectedConIndex}) => DisclosureDisCon(
        discon: discon,
        disconIndex: disconIndex,
        selectedConIndex: selectedConIndex,
      );
}
