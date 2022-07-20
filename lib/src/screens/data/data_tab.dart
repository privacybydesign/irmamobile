import 'package:flutter/material.dart';
import "package:collection/collection.dart";
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../models/credentials.dart';
import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/translated_text.dart';
import '../add_data/add_data_screen.dart';
import '../home/widgets/irma_action_card.dart';
import 'widgets/credential_category_list.dart';

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

class DataTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(
            vertical: theme.defaultSpacing,
            horizontal: theme.defaultSpacing,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  'data.tab.title',
                  style: theme.textTheme.headline2,
                ),
                SizedBox(height: theme.largeSpacing),
                IrmaActionCard(
                  titleKey: 'data.tab.obtain_data',
                  onTap: () => Navigator.of(context).pushNamed(AddDataScreen.routeName),
                  icon: Icons.add_circle_outline,
                  color: theme.themeData.colorScheme.secondary,
                  style: theme.textTheme.headline3,
                ),
              ],
            ),
          ),
        ),
        StreamBuilder(
          stream: repo.getCredentials(),
          builder: (context, AsyncSnapshot<Credentials> snapshot) {
            if (!snapshot.hasData) {
              return SliverToBoxAdapter(
                child: Container(),
              );
            }
            final filteredCredentials = snapshot.data!.values.where(
              (element) => !element.isKeyshareCredential,
            );

            final credentialTypesByCategoryNames = groupBy(
              _distinctCredentialTypes(
                filteredCredentials.map((e) => e.info.credentialType),
              ),
              (CredentialType credType) =>
                  credType.category.hasTranslation(lang) ? credType.category.translate(lang) : null,
            );
            return MultiSliver(
              children: [
                for (var credentialTypesByCategory
                    in credentialTypesByCategoryNames.entries.where((entry) => entry.key != null))
                  CredentialCategoryList(
                    categoryName: credentialTypesByCategory.key!,
                    credentialTypes: credentialTypesByCategory.value,
                  ),
                // If 'other' credentials are present, render them last
                if (credentialTypesByCategoryNames.containsKey(null))
                  CredentialCategoryList(
                    categoryName: FlutterI18n.translate(context, 'data.category_other'),
                    credentialTypes: _distinctCredentialTypes(
                      credentialTypesByCategoryNames[null]!,
                    ),
                  )
              ],
            );
          },
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: theme.mediumSpacing,
          ),
        )
      ],
    );
  }
}
