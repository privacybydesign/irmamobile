import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/translated_text.dart';
import '../activity/widgets/recent_activity.dart';

class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IrmaAppBar(
          noLeading: true,
          title: TranslatedText(
            'home.nav_bar.home',
            style: theme.themeData.textTheme.headline1,
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(
              vertical: theme.smallSpacing,
              horizontal: theme.defaultSpacing,
            ),
            shrinkWrap: true,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: theme.tinySpacing,
                ),
                child: TranslatedText(
                  'activity.recent_activity',
                  style: theme.textTheme.headline3,
                ),
              ),
              const RecentActivity(
                amountOfLogs: 2,
              )
            ],
          ),
        ),
      ],
    );
  }
}
