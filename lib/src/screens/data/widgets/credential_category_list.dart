import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:sliver_tools/sliver_tools.dart';

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

    return MultiSliver(
      children: [
        SliverPadding(
          padding: EdgeInsets.symmetric(
            vertical: theme.tinySpacing,
            horizontal: theme.defaultSpacing,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              categoryName,
              style: theme.textTheme.headline4,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            vertical: theme.tinySpacing,
            horizontal: theme.defaultSpacing,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CredentialsDetailScreen(
                      credentialTypeId: credentialTypes[index].fullId,
                    ),
                  ),
                ),
                child: CredentialTypeTile(
                  credentialTypes[index],
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
