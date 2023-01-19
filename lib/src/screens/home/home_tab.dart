import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_action_card.dart';
import '../activity/widgets/recent_activity.dart';
import '../add_data/add_data_screen.dart';
import 'widgets/irma_nav_bar.dart';

class HomeTab extends StatelessWidget {
  final Function(IrmaNavBarTab tab) onChangeTab;

  const HomeTab({
    required this.onChangeTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: theme.defaultSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IrmaActionCard(
            key: const Key('home_action_fetch'),
            titleKey: 'home_tab.action_card.fetch.title',
            subtitleKey: 'home_tab.action_card.fetch.subtitle',
            onTap: () => Navigator.of(context).pushNamed(AddDataScreen.routeName),
            icon: Icons.add_circle_outline,
            color: theme.themeData.colorScheme.primary,
          ),
          SizedBox(height: theme.largeSpacing),

          //Recent activity
          RecentActivity(
            onTap: () => onChangeTab(IrmaNavBarTab.activity),
          ),
          SizedBox(height: theme.defaultSpacing)
        ],
      ),
    );
  }
}
