import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import "package:collection/collection.dart";
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../data/irma_repository.dart';
import '../../models/credentials.dart';
import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/translated_text.dart';
import '../add_data/add_data_screen.dart';
import '../home/widgets/irma_action_card.dart';
import 'widgets/credential_category_list.dart';

class DataTab extends StatefulWidget {
  @override
  State<DataTab> createState() => _DataTabState();
}

class _DataTabState extends State<DataTab> {
  late final String lang;
  late final IrmaRepository repo;
  late final StreamSubscription<Credentials> credentialStreamSubscription;

  List<Credential> credentials = [];
  Map<String?, List<CredentialType>> credentialTypesByCategoryNames = {};

  void _credentialStreamListener(Credentials credentials) => setState(
        () => (credentialTypesByCategoryNames = groupBy(
          credentials.values.map((e) => e.info.credentialType),
          (CredentialType credType) =>
              credType.category.hasTranslation(lang) ? credType.category.translate(lang) : null,
        )),
      );

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      lang = FlutterI18n.currentLocale(context)!.languageCode;
      repo = IrmaRepositoryProvider.of(context);
      credentialStreamSubscription = repo.getCredentials().listen(_credentialStreamListener);
    });
  }

  @override
  void dispose() {
    credentialStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

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

        //Render credential category list for each category that is not 'other'
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
            credentialTypes: credentialTypesByCategoryNames[null]!,
          )
      ],
    );
  }
}
