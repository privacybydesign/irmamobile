import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/widgets/heading.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/logo_banner.dart';

class LogoBannerHeader extends StatelessWidget {
  final Image logo;
  final String header;
  final Widget bottomBar;
  final Widget child;
  final void Function() onBack;
  final GlobalKey scrollviewKey;
  final ScrollController controller;

  const LogoBannerHeader({
    this.logo,
    this.header,
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
            LogoBanner(logo: logo),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Heading(header, style: Theme.of(context).textTheme.headline5),
                ),
                child,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
