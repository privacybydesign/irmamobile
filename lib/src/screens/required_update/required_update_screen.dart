import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_info_scaffold_body.dart';

class RequiredUpdateScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const IrmaInfoScaffoldBody(
        imagePath: 'assets/error/update_request_illustration.svg',
        titleTranslationKey: 'update.title',
        bodyTranslationKey: 'update.explanation',
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, 'update.update_app'),
        onPrimaryPressed: () {
          late String url;
          if (Platform.isAndroid) {
            url = 'http://play.google.com/store/apps/details?id=org.irmacard.cardemu';
          } else if (Platform.isIOS) {
            url = 'https://apps.apple.com/app/id1294092994';
          } else {
            throw Exception('Unsupported platform');
          }
          launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalNonBrowserApplication,
          );
        },
      ),
    );
  }
}
