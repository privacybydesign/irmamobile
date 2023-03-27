import 'package:flutter/material.dart';

import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';

import '../../../theme/theme.dart';
import '../../../widgets/translated_text.dart';
import '../../scanner/scanner_screen.dart';
import '../../scanner/util/handle_camera_permission.dart';

class IrmaQrScanButton extends StatelessWidget {
  const IrmaQrScanButton({Key? key}) : super(key: key);

  Future<void> _onQrScanButtonTap(BuildContext context) async {
    final hasCameraPermission = await handleCameraPermission(context);

    if (hasCameraPermission) {
      Navigator.of(context).pushNamed(
        ScannerScreen.routeName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height > 450 ? 52 : 42),
      constraints: const BoxConstraints(maxWidth: 90),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 72,
            width: 72,
            child: Stack(
              children: [
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/ui/round-btn-bg.svg',
                  ),
                ),
                Positioned.fill(
                  child: ClipOval(
                    child: Material(
                      type: MaterialType.transparency,
                      child: Semantics(
                        button: true,
                        label: FlutterI18n.translate(context, 'home.nav_bar.scan_qr'),
                        child: InkWell(
                          onTap: () => _onQrScanButtonTap(context),
                          child: Icon(
                            Icons.qr_code_scanner_rounded,
                            color: theme.light,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            height: theme.tinySpacing,
          ),
          ExcludeSemantics(
            child: TranslatedText(
              'home.nav_bar.scan_qr',
              textAlign: TextAlign.center,
              style: theme.themeData.textTheme.headline6,
            ),
          ),
        ],
      ),
    );
  }
}
