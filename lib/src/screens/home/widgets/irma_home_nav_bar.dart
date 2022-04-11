import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

enum IrmaNavBarTab { home, data, activity, more }

class IrmaNavBar extends StatelessWidget {
  final _navBarTabTranslationKeys = {
    IrmaNavBarTab.home: 'home.nav_bar.home',
    IrmaNavBarTab.data: 'home.nav_bar.data',
    IrmaNavBarTab.activity: 'home.nav_bar.activity',
    IrmaNavBarTab.more: 'home.nav_bar.more'
  };

  final Function(IrmaNavBarTab tab) onChangeTab;
  final IrmaNavBarTab selectedTab;

  IrmaNavBar({Key? key, required this.onChangeTab, this.selectedTab = IrmaNavBarTab.home}) : super(key: key);

  Widget _buildNavButton(BuildContext context, IconData iconData, IrmaNavBarTab tab) => Expanded(
        child: InkWell(
          onTap: () {
            onChangeTab(tab);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconData,
                size: 28,
                color: selectedTab == tab ? IrmaTheme.of(context).themeData.colorScheme.primary : Colors.grey.shade600,
              ),
              const SizedBox(
                height: 4,
              ),
              TranslatedText(
                _navBarTabTranslationKeys[tab],
                style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    color:
                        selectedTab == tab ? IrmaTheme.of(context).themeData.colorScheme.primary : Colors.grey.shade600,
                    fontWeight: FontWeight.w600),
              )
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    Widget _buildQrButton() => Container(
          padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).tinySpacing),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade600.withOpacity(0.5),
                  blurRadius: 10.0,
                  spreadRadius: 1.0,
                  offset: const Offset(0, 7))
            ],
          ),
          child: CircleAvatar(
            backgroundColor: IrmaTheme.of(context).themeData.colorScheme.primary,
            radius: 36,
            child: IconButton(
                tooltip: FlutterI18n.translate(context, 'home.nav_bar.open_scanner'),
                color: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, ScannerScreen.routeName);
                },
                icon: const Icon(IrmaIcons.scanQrcode, size: 32)),
          ),
        );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).tinySpacing),
      // Reduce vertical padding for screens with limited height (i.e. landscape mode).
      height: MediaQuery.of(context).size.height > 450 ? 110 : 85,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade600.withOpacity(0.5),
              blurRadius: 10.0,
              spreadRadius: 1.0,
              offset: const Offset(0, 7))
        ],
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(context, Icons.home_filled, IrmaNavBarTab.home),
          _buildNavButton(context, Icons.folder_shared, IrmaNavBarTab.data),
          _buildQrButton(),
          _buildNavButton(context, Icons.history, IrmaNavBarTab.activity),
          _buildNavButton(context, Icons.more_horiz, IrmaNavBarTab.more),
        ],
      ),
    );
  }
}
