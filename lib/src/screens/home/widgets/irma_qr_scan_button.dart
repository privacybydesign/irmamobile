import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class IrmaQrScanButton extends StatelessWidget {
  const IrmaQrScanButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height > 450 ? 52 : 42),
      constraints: const BoxConstraints(maxWidth: 90),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: theme.themeData.colorScheme.secondary,
            radius: 36,
            child: IconButton(
                tooltip: FlutterI18n.translate(context, 'home.nav_bar.scan_qr'),
                color: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, ScannerScreen.routeName);
                },
                icon: const Icon(IrmaIcons.scanQrcode, size: 32)),
          ),
          SizedBox(
            height: theme.tinySpacing,
          ),
          ExcludeSemantics(
            child: TranslatedText('home.nav_bar.scan_qr',
                textAlign: TextAlign.center,
                style: theme.themeData.textTheme.caption!.copyWith(fontSize: 12, color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }
}
