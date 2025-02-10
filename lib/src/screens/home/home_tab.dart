import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_action_card.dart';
import '../activity/widgets/recent_activity.dart';
import 'widgets/irma_nav_bar.dart';

class HomeTab extends StatelessWidget {
  final Function(IrmaNavBarTab tab) onChangeTab;

  const HomeTab({
    required this.onChangeTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(
          theme.defaultSpacing,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IrmaActionCard(
              key: const Key('home_action_fetch'),
              titleKey: 'home_tab.action_card.fetch.title',
              subtitleKey: 'home_tab.action_card.fetch.subtitle',
              onTap: () => context.push('/add_data'),
              icon: Icons.add_circle_sharp,
            ),
            SizedBox(height: theme.largeSpacing),

            //Recent activity
            RecentActivity(
              onTap: () => onChangeTab(IrmaNavBarTab.activity),
            ),
            SizedBox(height: theme.defaultSpacing)
          ],
        ),
      ),
    );
  }
}
