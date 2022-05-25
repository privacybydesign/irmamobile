import 'package:collection/collection.dart';

import '../../../../models/attribute_value.dart';
import '../../../../models/attributes.dart';
import '../../../../models/credentials.dart';
import '../../../../models/irma_configuration.dart';

/// Abstract class that contains the overlapping behaviour of ChoosableDisclosureCredential and TemplateDisclosureCredential.
abstract class DisclosureCredential implements CredentialInfo {
  final UnmodifiableListView<Attribute> attributes;

  DisclosureCredential({required List<Attribute> attributes})
      : assert(attributes.isNotEmpty),
        assert(attributes.every((attr) => attr.credentialInfo.fullId == attributes.first.credentialInfo.fullId)),
        attributes = UnmodifiableListView(attributes);

  Iterable<Attribute> get attributesWithValue => attributes.where((att) => att.value is! NullValue);

  @override
  CredentialType get credentialType => attributes.first.credentialInfo.credentialType;

  @override
  String get fullId => attributes.first.credentialInfo.fullId;

  @override
  String get id => attributes.first.credentialInfo.id;

  @override
  Issuer get issuer => attributes.first.credentialInfo.issuer;

  @override
  SchemeManager get schemeManager => attributes.first.credentialInfo.schemeManager;

  /// Returns a new DisclosureCredential with the merged contents of this and the given other DisclosureCredential,
  /// if they don't contradict. Returns null otherwise.
  DisclosureCredential? copyAndMerge(DisclosureCredential other);
}
