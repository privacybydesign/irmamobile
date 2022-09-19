import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import '../../../../models/attribute_value.dart';
import '../../../../models/attributes.dart';
import '../../../../models/credentials.dart';
import '../../../../models/irma_configuration.dart';

/// Abstract class that contains the overlapping behaviour of ChoosableDisclosureCredential and TemplateDisclosureCredential.
abstract class DisclosureCredential extends Equatable implements CredentialInfo {
  final UnmodifiableListView<Attribute> attributes;
  final CredentialAttribute? credentialAttribute;

  DisclosureCredential({required List<Attribute> attributes})
      : assert(attributes.isNotEmpty),
        assert(attributes.every((attr) => attr.credentialInfo.fullId == attributes.first.credentialInfo.fullId)),
        credentialAttribute =
            attributes.firstWhereOrNull((attrib) => attrib is CredentialAttribute) as CredentialAttribute?,
        attributes = UnmodifiableListView(attributes);

  Iterable<Attribute> get attributesWithValue => attributes.where((att) => att.value is! NullValue);

  DateTime? get expires => credentialAttribute?.credential.expires;
  bool get revoked => credentialAttribute?.credential.revoked ?? false;

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

  @override
  List<Object?> get props => [
        {for (final attr in attributes) attr.attributeType.fullId: attr.value.raw}
      ];
}
