import "dart:io";

import "package:material_ui/material_ui.dart";
import "package:url_launcher/url_launcher.dart";

import "../../theme/yivi_tone.dart";
import "../../util/i18n.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/status_screen.dart";

class RequiredUpdateScreen extends StatelessWidget {
  const RequiredUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StatusScreen(
      icon: Icons.download_rounded,
      tone: YiviTone.info,
      title: context.tr("update.title"),
      message: context.tr("update.explanation"),
      actions: IrmaBottomBar(
        primaryButtonLabel: context.tr("update.update_app"),
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
