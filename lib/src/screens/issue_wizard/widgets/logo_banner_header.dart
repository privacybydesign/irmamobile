import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/logo_banner.dart';

class LogoBannerHeader extends StatelessWidget {
  final Image logo;
  final String header;
  final Color backgroundColor;
  final Color textColor;
  final Widget bottomBar;
  final Widget child;
  final void Function() onBack;
  final GlobalKey scrollviewKey;
  final ScrollController controller;

  const LogoBannerHeader({
    this.logo,
    this.header,
    this.backgroundColor,
    this.textColor,
    this.bottomBar,
    this.child,
    this.scrollviewKey,
    this.controller,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: Text(FlutterI18n.translate(context, "issue_wizard.add_cards")),
        leadingAction: onBack,
        leadingIcon: Icon(Icons.arrow_back, semanticLabel: FlutterI18n.translate(context, "accessibility.back")),
      ),
      bottomNavigationBar: bottomBar,
      body: SingleChildScrollView(
        controller: controller,
        key: scrollviewKey,
        child: Column(
          children: <Widget>[
            LogoBanner(
              text: header,
              logo: logo,
              backgroundColor: backgroundColor,
              textColor: textColor,
            ),
            Padding(
              padding: EdgeInsets.only(top: IrmaTheme.of(context).mediumSpacing),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
