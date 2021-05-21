import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/about/about_screen.dart';
import 'package:irmamobile/src/screens/add_cards/card_store_screen.dart';
import 'package:irmamobile/src/screens/help/help_screen.dart';
import 'package:irmamobile/src/screens/history/history_screen.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/invisible_scroll_configuration.dart';

class WalletDrawer extends StatelessWidget {
  final IrmaRepository _repo = IrmaRepository.get();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: Container(
          color: IrmaTheme.of(context).primaryLight,
          child: Column(
            children: <Widget>[
              Expanded(
                child: ScrollConfiguration(
                  behavior: InvisibleScrollBehavior(),
                  child: ListView(
                    // Important: Remove any padding from the ListView.
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      Container(
                        height: Size.fromHeight(kToolbarHeight).height,
                        child: DrawerHeader(
                          decoration: BoxDecoration(
                            border: Border.all(width: 0.0, color: Colors.white),
                            color: IrmaTheme.of(context).grayscale85,
                          ),
                          padding: EdgeInsets.only(
                            left: IrmaTheme.of(context).mediumSpacing,
                            right: IrmaTheme.of(context).defaultSpacing,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              SizedBox.fromSize(
                                size: const Size(50.0, 32.0),
                                child: SvgPicture.asset(
                                  'assets/non-free/irma_logo.svg',
                                  semanticsLabel: FlutterI18n.translate(
                                    context,
                                    'accessibility.irma_logo',
                                  ),
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.topLeft,
                                ),
                              ),
                              IconButton(
                                iconSize: 18.0,
                                icon: Icon(IrmaIcons.close,
                                    semanticLabel: FlutterI18n.translate(context, "wallet.close_menu")),
                                onPressed: () => Navigator.pop(context),
                              )
                            ],
                          ),
                        ),
                      ),
                      _createDrawerItem(context,
                          icon: IrmaIcons.add,
                          key: const Key('menu_add_cards'),
                          text: FlutterI18n.translate(context, 'drawer.add_cards'), onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(CardStoreScreen.routeName);
                      }),
                      _createDrawerItem(context,
                          icon: IrmaIcons.time,
                          key: const Key('menu_history'),
                          text: FlutterI18n.translate(context, 'drawer.history'), onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(HistoryScreen.routeName);
                      }),
                      _createDrawerItem(context,
                          icon: IrmaIcons.settings, text: FlutterI18n.translate(context, 'drawer.settings'), onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(SettingsScreen.routeName);
                      }),
                      _createDrawerItem(
                        context,
                        icon: IrmaIcons.question,
                        text: FlutterI18n.translate(context, 'drawer.help'),
                        onTap: () => Navigator.pushNamed(context, HelpScreen.routeName),
                      ),
                      _createDrawerItem(context,
                          icon: IrmaIcons.info, text: FlutterI18n.translate(context, 'drawer.about'), onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(AboutScreen.routeName);
                      }),
                    ],
                  ),
                ),
              ),
              // This container holds the align
              Container(
                // This align moves the children to the bottom
                child: Align(
                  alignment: FractionalOffset.bottomCenter,
                  // This container holds all the children that will be aligned
                  // on the bottom and should not scroll with the above ListView
                  child: Container(
                    color: IrmaTheme.of(context).primaryBlue,
                    child: Semantics(
                        button: true,
                        child: ListTile(
                          contentPadding: EdgeInsets.only(left: IrmaTheme.of(context).mediumSpacing),
                          title: Text(
                            FlutterI18n.translate(context, 'drawer.lock_wallet'),
                            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                          leading: Icon(IrmaIcons.lock, color: Colors.white),
                          onTap: () {
                            _repo.lock();
                            Navigator.of(context).pop();
                          },
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createDrawerItem(BuildContext context, {Key key, IconData icon, String text, GestureTapCallback onTap}) {
    return Semantics(
        button: true,
        child: ListTile(
          key: key,
          contentPadding: EdgeInsets.only(left: IrmaTheme.of(context).mediumSpacing),
          title: Text(
            text,
            style: IrmaTheme.of(context).textTheme.body1,
          ),
          leading: Icon(icon, color: IrmaTheme.of(context).primaryDark),
          onTap: onTap,
        ));
  }
}
