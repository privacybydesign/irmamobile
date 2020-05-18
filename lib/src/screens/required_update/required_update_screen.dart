import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class RequiredUpdateScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(FlutterI18n.translate(context, 'update.required')),
      ),
      bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: FlutterI18n.translate(context, 'update.doupdate'),
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
          }),
    );
  }
}
