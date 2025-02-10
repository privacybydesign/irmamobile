import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_action_card.dart';
import 'widgets/credential_category_list.dart';
import 'widgets/credential_types_builder.dart';

class DataTab extends StatelessWidget {
  _navToCredTypeDetailScreen(
    BuildContext context,
    String credentialTypeId,
    String categoryName,
  ) {
    context.push('/credentials_details', extra: (credentialTypeId, categoryName));
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IrmaActionCard(
              titleKey: 'data.tab.obtain_data',
              onTap: () => context.push('/add_data'),
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
      ),
    );
  }
}
