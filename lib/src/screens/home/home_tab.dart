import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/translated_text.dart';
import '../activity/widgets/recent_activity.dart';

class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      IrmaAppBar(
        title: TranslatedText(
          'home.nav_bar.home',
          style: IrmaTheme.of(context).themeData.textTheme.headline1,
        ),
        noLeading: true,
      ),
      Expanded(
        child: ListView(
          padding: EdgeInsets.symmetric(
              vertical: IrmaTheme.of(context).smallSpacing, horizontal: IrmaTheme.of(context).defaultSpacing),
          shrinkWrap: true,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).tinySpacing),
              child: TranslatedText(
                'activity.recent_activity',
                style: IrmaTheme.of(context).textTheme.headline3,
              ),
            ),
            const RecentActivity(
              amountOfLogs: 2,
            )
          ],
        ),
      ),
    ]);
  }
}
