import "dart:io";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";
import "package:url_launcher/url_launcher.dart";

import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_info_scaffold_body.dart";

class RequiredUpdateScreen extends StatelessWidget {
  const RequiredUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IrmaInfoScreen(
      icon: Icons.download_rounded,
      tone: DialogTone.info,
      titleTranslationKey: "update.title",
      bodyTranslationKey: "update.explanation",
      bottomBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, "update.update_app"),
        onPrimaryPressed: () {
          late String url;
          if (Platform.isAndroid) {
            url =
                "https://play.google.com/store/apps/details?id=org.irmacard.cardemu";
          } else if (Platform.isIOS) {
            url = "https://apps.apple.com/app/id1294092994";
          } else {
            throw Exception("Unsupported platform");
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
