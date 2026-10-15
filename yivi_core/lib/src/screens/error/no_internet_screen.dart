import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_info_scaffold_body.dart";

class NoInternetScreen extends StatelessWidget {
  final VoidCallback onTapClose;
  final VoidCallback? onTapRetry;

  const NoInternetScreen({required this.onTapClose, this.onTapRetry})
    : super(key: const ValueKey("no_internet_screen"));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: YiviPalette.of(context).background,
      appBar: IrmaAppBar(
        titleTranslationKey: "error.details_title",
        leading: YiviBackButton(onTap: onTapClose),
      ),
      body: IrmaInfoScaffoldBody(
        icon: Icons.wifi_off_rounded,
        tone: DialogTone.info,
        titleTranslationKey: "error.no_internet_title",
        bodyTranslationKey: "error.types.no_internet",
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, "error.button_back"),
        onPrimaryPressed: onTapClose,
        secondaryButtonLabel: onTapRetry == null
            ? null
            : FlutterI18n.translate(context, "error.button_retry"),
        onSecondaryPressed: onTapRetry,
      ),
    );
  }
}
