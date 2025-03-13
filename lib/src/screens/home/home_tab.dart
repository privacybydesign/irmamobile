import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/theme.dart';
import '../../util/navigation.dart';
import '../../widgets/irma_action_card.dart';
import '../../widgets/irma_app_bar.dart';
import '../activity/widgets/recent_activity.dart';
import '../notifications/bloc/notifications_bloc.dart';
import '../notifications/widgets/notification_bell.dart';
import 'widgets/irma_nav_bar.dart';

class HomeTab extends StatelessWidget {
  final Function(IrmaNavBarTab tab) onChangeTab;

  const HomeTab({
    required this.onChangeTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: IrmaTheme.of(context).backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'home_tab.title',
        leading: null,
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) => NotificationBell(
              showIndicator: state is NotificationsLoaded ? state.hasUnreadNotifications : false,
              onTap: context.goNotificationsScreen,
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SizedBox(
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
                  onTap: context.pushAddDataScreen,
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
        ),
      ),
    );
  }
}
