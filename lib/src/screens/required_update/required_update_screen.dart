import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/translated_text.dart';

class RequiredUpdateScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(theme.largeSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cached,
              color: theme.themeData.colorScheme.primary,
              size: 125,
            ),
            SizedBox(
              height: theme.mediumSpacing,
            ),
            TranslatedText(
              'update.title',
              style: theme.textTheme.headline1,
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: theme.mediumSpacing,
            ),
            TranslatedText(
              'update.explanation',
              style: theme.textTheme.bodyText2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, 'update.update_app'),
        onPrimaryPressed: () {
          switch (Platform.operatingSystem) {
            case "android":
              launch("market://details?id=org.irmacard.cardemu");
              break;
            case "ios":
              launch("itms://itunes.apple.com/us/app/apple-store/id1294092994?mt=8");
              break;
            default:
              throw Exception("Unsupported Platfrom.operatingSystem");
          }
        },
      ),
    );
  }
}
