import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../irma_bottom_sheet.dart';
import '../irma_divider.dart';
import '../translated_text.dart';

class IrmaCredentialCardOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onReobtain;

  const IrmaCredentialCardOptionsBottomSheet({
    required this.onDelete,
    required this.onReobtain,
  });

  ListTile _buildOptionTile({
    required IconData icon,
    required String translationKey,
    required IrmaThemeData theme,
    Function()? onTap,
  }) =>
      ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color: theme.themeData.colorScheme.secondary,
        ),
        title: TranslatedText(
          translationKey,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            'credential.options.title',
            style: theme.textTheme.headline3,
          ),
          SizedBox(height: theme.defaultSpacing),
          _buildOptionTile(
            theme: theme,
            icon: Icons.cached,
            translationKey: 'credential.options.reobtain',
            onTap: onReobtain,
          ),
          const IrmaDivider(),
          _buildOptionTile(
            theme: theme,
            icon: Icons.delete,
            translationKey: 'credential.options.delete',
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
