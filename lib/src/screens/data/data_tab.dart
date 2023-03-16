import 'package:flutter/material.dart';

import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_action_card.dart';
import '../add_data/add_data_screen.dart';
import 'credentials_detail_screen.dart';
import 'widgets/credential_category_list.dart';
import 'widgets/credential_types_builder.dart';

class DataTab extends StatelessWidget {
  _navToCredTypeDetailScreen(
    BuildContext context,
    String credentialTypeId,
    String categoryName,
  ) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CredentialsDetailScreen(
            categoryName: categoryName,
            credentialTypeId: credentialTypeId,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(theme.defaultSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IrmaActionCard(
            titleKey: 'data.tab.obtain_data',
            onTap: () => Navigator.of(context).pushNamed(AddDataScreen.routeName),
            icon: Icons.add_circle_sharp,
          ),
          CredentialTypesBuilder(
            builder: (context, groupedCredentialTypes) => Column(
              children: groupedCredentialTypes.entries
                  .map(
                    (credentialTypesByCategory) => CredentialCategoryList(
                      categoryName: credentialTypesByCategory.key,
                      credentialTypes: credentialTypesByCategory.value,
                      onCredentialTypeTap: (CredentialType credType) => _navToCredTypeDetailScreen(
                        context,
                        credType.fullId,
                        credentialTypesByCategory.key,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          SizedBox(
            height: theme.defaultSpacing,
          )
        ],
      ),
    );
  }
}
