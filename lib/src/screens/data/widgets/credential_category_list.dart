import 'package:flutter/material.dart';

import 'package:sliver_tools/sliver_tools.dart';

import '../../../models/irma_configuration.dart';
import '../../../theme/theme.dart';
import '../credentials_detail_screen.dart';

import 'credential_type_tile.dart';

class CredentialCategoryList extends StatelessWidget {
  final String categoryName;
  final List<CredentialType> credentialTypes;

  const CredentialCategoryList({
    required this.categoryName,
    required this.credentialTypes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return MultiSliver(
      children: [
        SliverPadding(
          padding: EdgeInsets.symmetric(
            vertical: theme.tinySpacing,
            horizontal: theme.defaultSpacing,
          ),
          sliver: SliverToBoxAdapter(
            child: Semantics(
              header: true,
              child: Text(
                categoryName,
                style: theme.textTheme.headline4,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            vertical: theme.tinySpacing,
            horizontal: theme.defaultSpacing,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isLandscape ? 4 : 2,
              childAspectRatio: isLandscape ? 1.05 : 1.15,
              mainAxisSpacing: 2.50,
              crossAxisSpacing: 2.50,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => GestureDetector(
                key: Key(credentialTypes[index].fullId + '_tile'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CredentialsDetailScreen(
                        categoryName: categoryName,
                        credentialTypeId: credentialTypes[index].fullId,
                      ),
                    ),
                  );
                  Feedback.forTap(context);
                },
                child: Semantics(
                  button: true,
                  child: CredentialTypeTile(
                    credentialTypes[index],
                  ),
                ),
              ),
              childCount: credentialTypes.length,
            ),
          ),
        ),
      ],
    );
  }
}
