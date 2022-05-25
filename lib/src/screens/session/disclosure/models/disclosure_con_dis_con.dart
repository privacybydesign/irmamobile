import 'package:collection/collection.dart';

import '../../../../models/irma_configuration.dart';
import 'disclosure_dis_con.dart';

class DisclosureConDisCon extends Iterable<DisclosureDisCon> {
  final List<DisclosureDisCon> _wrapped;

  DisclosureConDisCon(this._wrapped)
      : assert(_wrapped.groupListsBy((discon) => discon.disconIndex).values.every((group) => group.length == 1));

  /// List with all required DisCons.
  Iterable<DisclosureDisCon> get required => _wrapped.where((choice) => !choice.isOptional);

  /// List with all optional DisCons.
  Iterable<DisclosureDisCon> get optional => _wrapped.where((choice) => choice.isOptional);

  /// Returns which credential types are involved in this step.
  Set<CredentialType> get includedCredentialTypes =>
      _wrapped.fold({}, (prev, choice) => {...prev, ...choice.credentialTypesIncluded});

  /// Returns the DisclosureDisCon with the given conIndex (if present).
  DisclosureDisCon? operator [](int disconIndex) =>
      _wrapped.firstWhereOrNull((discon) => discon.disconIndex == disconIndex);

  DisclosureConDisCon copyWith({required int disconIndex, required int selectedConIndex}) => DisclosureConDisCon(
        _wrapped
            .map((discon) =>
                discon.disconIndex == disconIndex ? discon.copyWith(selectedConIndex: selectedConIndex) : discon)
            .toList(),
      );

  @override
  Iterator<DisclosureDisCon> get iterator => _wrapped.iterator;
}
