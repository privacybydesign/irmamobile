import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/credentials.dart';
import '../../../models/irma_configuration.dart';
import '../../../util/language.dart';
import '../../../widgets/irma_repository_provider.dart';
import '../../../widgets/progress.dart';

typedef GroupedCredentialTypesBuilder = Widget Function(
  BuildContext context,
  Map<String, List<CredentialType>> groupedCredentialTypes,
);

class CredentialTypesBuilder extends StatelessWidget {
  final GroupedCredentialTypesBuilder builder;

  const CredentialTypesBuilder({
    required this.builder,
  });

  List<CredentialType> _distinctCredentialTypes(Iterable<CredentialType> credentialTypes) {
    var idSet = <String>{};
    var distinct = <CredentialType>[];
    for (var credType in credentialTypes) {
      if (idSet.add(credType.fullId)) {
        distinct.add(credType);
      }
    }
    return distinct;
  }

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);

    return StreamBuilder(
      stream: repo.getCredentials(),
      builder: (context, AsyncSnapshot<Credentials> snapshot) {
        if (!snapshot.hasData) return IrmaProgress();

        final credentials = snapshot.data!;

        // Filter out keyshare credentials
        final nonKeyShareCredentials = credentials.values.where(
          (cred) => !cred.isKeyshareCredential,
        );

        // Map them to their credential types
        final nonKeyShareCredentialTypes = nonKeyShareCredentials.map(
          (e) => e.info.credentialType,
        );

        // Filter out duplicates
        final distinctCredentialTypes = _distinctCredentialTypes(nonKeyShareCredentialTypes);

        // Group them by category
        final otherTranslation = FlutterI18n.translate(context, 'data.category_other');
        var groupedCredentialTypes = groupBy<CredentialType, String>(
          distinctCredentialTypes,
          (ct) => ct.category.isNotEmpty ? getTranslation(context, ct.category) : otherTranslation,
        );

        // Make sure other credentials are always at the end
        final otherCredentials = groupedCredentialTypes.remove(otherTranslation);
        if (otherCredentials != null) {
          groupedCredentialTypes[otherTranslation] = otherCredentials;
        }

        return builder(
          context,
          groupedCredentialTypes,
        );
      },
    );
  }
}
