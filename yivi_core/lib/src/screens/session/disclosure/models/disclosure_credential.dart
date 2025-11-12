import 'package:equatable/equatable.dart';

import '../../../../models/credentials.dart';

/// Abstract class that contains the overlapping behaviour of ChoosableDisclosureCredential and TemplateDisclosureCredential.
abstract class DisclosureCredential extends CredentialView with EquatableMixin {
  DisclosureCredential({
    required super.info,
    required super.attributes,
    super.expired,
    super.revoked,
  });

  @override
  List<Object?> get props => [
        {for (final attr in attributes) attr.attributeType.fullId: attr.value.raw}
      ];
}
