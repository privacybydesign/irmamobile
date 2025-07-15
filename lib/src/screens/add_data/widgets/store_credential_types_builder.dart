import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/credentials.dart';
import '../../../models/irma_configuration.dart';
import '../../../providers/irma_repository_provider.dart';
import '../../../util/language.dart';
import '../../../widgets/progress.dart';

typedef GroupedCredentialTypesBuilder =
    Widget Function(
      BuildContext context,
      Map<String, List<CredentialType>> groupedCredentialTypes,
      Map<String, List<CredentialType>> groupedObtainedCredentialTypes,
    );

class StoreCredentialTypesBuilder extends StatelessWidget {
  final GroupedCredentialTypesBuilder builder;

  const StoreCredentialTypesBuilder({required this.builder});

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);

    return StreamBuilder(
      stream: repo.getCredentials(),
      builder: (context, AsyncSnapshot<Credentials> snapshot) {
        if (!snapshot.hasData) return IrmaProgress();

        // Get all credentials that the user has already obtained.
        final obtainedCredentials = snapshot.data!;
        final obtainedCredentialTypes = obtainedCredentials.values.map((cred) => cred.info.credentialType);
        // And group them by category
        final otherTranslation = FlutterI18n.translate(context, 'data.category_other');
        var groupedObtainedCredentialTypes = groupBy<CredentialType, String>(
          obtainedCredentialTypes,
          (ct) => ct.category.isNotEmpty ? getTranslation(context, ct.category) : otherTranslation,
        );

        // Now get all the credential types that are in the credential store
        final storeCredentialTypes = repo.irmaConfiguration.credentialTypes.values.where(
          (ct) => ct.isInCredentialStore,
        );

        // Group them by category as well
        var groupedStoreCredentialTypes = groupBy<CredentialType, String>(
          storeCredentialTypes,
          (cred) => cred.category.isNotEmpty ? getTranslation(context, cred.category) : otherTranslation,
        );

        // Make sure personal credentials are always at the top
        final personalTranslation = FlutterI18n.translate(context, 'data.category_personal');
        final personalCredentials = groupedStoreCredentialTypes.remove(personalTranslation);
        if (personalCredentials != null) {
          groupedStoreCredentialTypes = {personalTranslation: personalCredentials, ...groupedStoreCredentialTypes};
        }

        // Make sure other credentials are always at the end
        final otherCredentials = groupedStoreCredentialTypes.remove(otherTranslation);
        if (otherCredentials != null) {
          groupedStoreCredentialTypes[otherTranslation] = otherCredentials;
        }

        return builder(context, groupedStoreCredentialTypes, groupedObtainedCredentialTypes);
      },
    );
  }
}
