import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../util/navigation.dart';
import '../../widgets/irma_action_card.dart';
import '../../widgets/irma_app_bar.dart';
import '../notifications/bloc/notifications_bloc.dart';
import '../notifications/widgets/notification_bell.dart';
import 'widgets/credential_category_list.dart';
import 'widgets/credential_types_builder.dart';

class DataTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: IrmaTheme.of(context).backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'home.nav_bar.data',
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
      body: SizedBox(
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
      ),
    );
  }
}
