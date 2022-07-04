import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/credentials.dart';
import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../util/combine.dart';
import '../../util/language.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_card.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/progress.dart';
import '../../widgets/translated_text.dart';
import 'add_data_details_screen.dart';

class AddDataScreen extends StatelessWidget {
  static const String routeName = '/add_data';

  static const _logoContainerSize = 48.0;

  Widget _buildCredentialTypeItem(BuildContext context, Issuer issuer, CredentialType credType, bool alreadyObtained) {
    final logoFile = File(credType.logo ?? '');
    final theme = IrmaTheme.of(context);
    final fullyObtained = credType.isSingleton && alreadyObtained;
    return IrmaCard(
      padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
      onTap: fullyObtained
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddDataDetailsScreen(credentialType: credType),
                ),
              ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(theme.smallSpacing),
            height: _logoContainerSize,
            width: _logoContainerSize,
            child: logoFile.existsSync()
                ? SizedBox(
                    height: _logoContainerSize / 2,
                    child: Image.file(logoFile, excludeFromSemantics: true),
                  )
                : null,
          ),
          SizedBox(width: theme.smallSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslation(context, credType.name),
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  getTranslation(context, issuer.name),
                  style: theme.textTheme.subtitle1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: theme.smallSpacing),
          Icon(
            fullyObtained ? Icons.check_circle : Icons.add_circle_outline,
            color: fullyObtained ? theme.notificationSuccess : null,
            size: _logoContainerSize * 0.7,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const IrmaAppBar(
          title: TranslatedText('add_data.title'),
        ),
        body: StreamBuilder<CombinedState2<IrmaConfiguration, Credentials>>(
          stream: combine2(
            IrmaRepositoryProvider.of(context).getIrmaConfiguration(),
            IrmaRepositoryProvider.of(context).getCredentials(),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const IrmaProgress();

            final irmaConfiguration = snapshot.data!.a;
            final credentials = snapshot.data!.b;

            final theme = IrmaTheme.of(context);

            final credentialTypes = irmaConfiguration.credentialTypes.values.where(
              (ct) => ct.isInCredentialStore,
            );

            final otherTranslation = FlutterI18n.translate(context, 'add_data.category_other');
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
                children: <Widget>[
                  TranslatedText(
                    'add_data.choose',
                    style: IrmaTheme.of(context).textTheme.bodyText2,
                  ),
                  SizedBox(height: theme.mediumSpacing),
                  for (final category in categories) ...[
                    Text(
                      category,
                      style: theme.textTheme.headline3,
                    ),
                    for (final credType in credentialTypesByCategory[category]!)
                      _buildCredentialTypeItem(
                        context,
                        irmaConfiguration.issuers[credType.fullIssuerId]!,
                        credType,
                        credentials.values.any((cred) => cred.info.fullId == credType.fullId),
                      ),
                    SizedBox(height: theme.defaultSpacing),
                  ]
                ],
              ),
            );
          },
        ),
      );
}
