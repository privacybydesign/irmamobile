import 'package:collection/collection.dart';

import '../../../models/attributes.dart';
import '../../../models/credentials.dart';
import '../../../models/irma_configuration.dart';

/// Abstract class that contains the overlapping behaviour of DisclosureCredential and DisclosureCredentialTemplate.
/// TODO: Naming
abstract class AbstractDisclosureCredential implements CredentialInfo {
  final UnmodifiableListView<Attribute> attributes;

  AbstractDisclosureCredential({required List<Attribute> attributes})
      : assert(attributes.isNotEmpty),
        assert(attributes.every((attr) => attr.credentialInfo.fullId == attributes.first.credentialInfo.fullId)),
        attributes = UnmodifiableListView(attributes);

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
}
