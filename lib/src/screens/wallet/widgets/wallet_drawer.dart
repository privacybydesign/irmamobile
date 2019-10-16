import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';

// TODO:
//"drawer": {
//"lock_wallet": "Lock wallet",
//"add_cards": "Add cards",
//"settings": "Settings",
//"history": "Usage history",
//"about": "About IRMA"
//},

class WalletDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              child: SvgPicture.asset('assets/non-free/irma_logo.svg'),
            ),
          ),
          _createDrawerItem(icon: Icons.lock, text: FlutterI18n.translate(context, 'drawer.lock_wallet'), onTap: () {}),
          _createDrawerItem(icon: Icons.add, text: FlutterI18n.translate(context, 'drawer.add_cards'), onTap: () {}),
          _createDrawerItem(icon: Icons.history, text: FlutterI18n.translate(context, 'drawer.history'), onTap: () {}),
          _createDrawerItem(
              icon: Icons.settings,
              text: FlutterI18n.translate(context, 'drawer.settings'),
              onTap: () => Navigator.pushNamed(context, '/settings')),
          _createDrawerItem(
              icon: Icons.help_outline,
              text: FlutterI18n.translate(context, 'drawer.about'),
              onTap: () => Navigator.pushNamed(context, '/about')),
        ],
      ),
    );
  }

  Widget _createDrawerItem({IconData icon, String text, GestureTapCallback onTap}) {
    return ListTile(
      title: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      leading: Icon(icon, color: Colors.black),
      onTap: onTap,
    );
  }
}
