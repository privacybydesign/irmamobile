import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/credentials.dart';
import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../util/combine.dart';
import '../../util/language.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/progress.dart';
import '../../widgets/translated_text.dart';
import 'widgets/add_data_tile.dart';

class AddDataScreen extends StatelessWidget {
  static const String routeName = '/add_data';

  List<AddDataTile> _buildCategoryAddDataTiles({
    required IrmaConfiguration irmaConfig,
    required List<CredentialType> categoryCredentialTypes,
    required Credentials alreadyObtainedCredentials,
  }) {
    List<AddDataTile> addDataTiles = [];

    for (var credType in categoryCredentialTypes) {
      bool alreadyObtained = alreadyObtainedCredentials.values.any(
        (cred) => cred.info.fullId == credType.fullId,
      );

      if (!credType.isSingleton || !alreadyObtained) {
        addDataTiles.add(
          AddDataTile(
            issuer: irmaConfig.issuers[credType.fullIssuerId]!,
            credType: credType,
            obtained: alreadyObtained,
          ),
        );
      }
    }

    return addDataTiles;
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: const IrmaAppBar(
        titleTranslationKey: 'data.add.title',
      ),
      body: SafeArea(
        child: StreamBuilder<CombinedState2<IrmaConfiguration, Credentials>>(
          stream: combine2(
            IrmaRepositoryProvider.of(context).getIrmaConfiguration(),
            IrmaRepositoryProvider.of(context).getCredentials(),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return IrmaProgress();

            final irmaConfiguration = snapshot.data!.a;
            final credentials = snapshot.data!.b;

            final credentialTypes = irmaConfiguration.credentialTypes.values.where(
              (ct) => ct.isInCredentialStore,
            );

            final otherTranslation = FlutterI18n.translate(context, 'data.category_other');
            final credentialTypesByCategory = groupBy<CredentialType, String>(
              credentialTypes,
              (ct) => ct.category.isNotEmpty ? getTranslation(context, ct.category) : otherTranslation,
            );
            final categories = credentialTypesByCategory.keys.toList(growable: true);
            // Make sure that 'Other' category is always at the end.
            if (categories.remove(otherTranslation)) categories.add(otherTranslation);

            return SingleChildScrollView(
              padding: EdgeInsets.all(theme.defaultSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    'data.add.choose',
                    style: theme.textTheme.bodyText2,
                  ),
                  SizedBox(height: theme.mediumSpacing),
                  for (final category in categories) ...[
                    Text(
                      category,
                      style: theme.textTheme.headline4!.copyWith(
                        color: theme.neutralExtraDark,
                      ),
                    ),
                    SizedBox(height: theme.smallSpacing),
                    ..._buildCategoryAddDataTiles(
                      irmaConfig: irmaConfiguration,
                      categoryCredentialTypes: credentialTypesByCategory[category]!,
                      alreadyObtainedCredentials: credentials,
                    ),
                    SizedBox(height: theme.defaultSpacing),
                  ]
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
