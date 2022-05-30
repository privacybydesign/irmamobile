import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_info_scaffold_body.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/irma_bottom_bar.dart';

class RequiredUpdateScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kDebugMode
          ? IrmaAppBar(
              title: const Text(
                "This won't appear on the release build",
              ),
              // ignore: avoid_redundant_argument_values
              noLeading: kReleaseMode,
              leadingAction: () {
                if (kDebugMode) {
                  Navigator.pop(context);
                }
              },
            )
          : null,
      body: const IrmaInfoScaffoldBody(
        icon: Icons.cached,
        titleKey: 'update.title',
        bodyKey: 'update.explanation',
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
