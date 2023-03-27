import 'package:flutter/material.dart';

import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/translated_text.dart';
import '../data/widgets/credential_category_list.dart';
import 'add_data_details_screen.dart';
import 'widgets/store_credential_types_builder.dart';

class AddDataScreen extends StatelessWidget {
  static const String routeName = '/add_data';

  _navToAddDataDetailScreen(
    BuildContext context,
    CredentialType credentialType,
  ) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddDataDetailsScreen(
            credentialType: credentialType,
            onCancel: () => Navigator.of(context).pop(),
            onAdd: () => IrmaRepositoryProvider.of(context).openIssueURL(
              context,
              credentialType.fullId,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: const IrmaAppBar(
        titleTranslationKey: 'data.add.title',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                'data.add.choose',
                style: theme.textTheme.bodyText2,
              ),
              SizedBox(
                height: theme.defaultSpacing,
              ),
              StoreCredentialTypesBuilder(
                builder: (
                  context,
                  groupedCredentialTypes,
                  groupedObtainedCredentialTypes,
                ) =>
                    Column(
                  children: groupedCredentialTypes.entries
                      .map(
                        (credentialTypesByCategory) => CredentialCategoryList(
                          categoryName: credentialTypesByCategory.key,
                          credentialTypes: credentialTypesByCategory.value,
                          obtainedCredentialTypes: groupedObtainedCredentialTypes[credentialTypesByCategory.key],
                          credentialTypeTrailingIcon: Icons.add_circle_sharp,
                          onCredentialTypeTap: (CredentialType credType) => _navToAddDataDetailScreen(
                            context,
                            credType,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
