import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/add_data/add_data_screen.dart';

import '../../theme/theme.dart';
import '../../widgets/translated_text.dart';
import '../home/widgets/irma_action_card.dart';

class DataTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        vertical: theme.mediumSpacing,
        horizontal: theme.defaultSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            'data_tab.title',
            style: theme.textTheme.headline2,
          ),
          SizedBox(height: theme.largeSpacing),
          IrmaActionCard(
            titleKey: 'data_tab.obtain_data',
            onTap: () => Navigator.of(context).pushNamed(AddDataScreen.routeName),
            icon: Icons.add_circle_outline,
            color: theme.themeData.colorScheme.secondary,
            style: theme.textTheme.headline3,
          ),
        ],
      ),
    );
  }
}
