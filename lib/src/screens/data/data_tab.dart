import 'package:flutter/material.dart';

import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../util/navigation.dart';
import '../../widgets/irma_action_card.dart';
import 'widgets/credential_category_list.dart';
import 'widgets/credential_types_builder.dart';

class DataTab extends StatelessWidget {
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
              onTap: context.pushAddDataScreen,
              icon: Icons.add_circle_sharp,
            ),
            CredentialTypesBuilder(
              builder: (context, groupedCredentialTypes) => Column(
                children: groupedCredentialTypes.entries
                    .map(
                      (credentialTypesByCategory) => CredentialCategoryList(
                        categoryName: credentialTypesByCategory.key,
                        credentialTypes: credentialTypesByCategory.value,
                        onCredentialTypeTap: (CredentialType credType) => context.pushCredentialsDetailsScreen(
                          CredentialsDetailsRouteParams(
                            credentialTypeId: credType.fullId,
                            categoryName: credentialTypesByCategory.key,
                          ),
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
