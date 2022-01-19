// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:irmamobile/src/prototypes/design_bottombar.dart';
import 'package:irmamobile/src/prototypes/design_buttons.dart';
import 'package:irmamobile/src/prototypes/design_colors.dart';
import 'package:irmamobile/src/prototypes/design_fields.dart';
import 'package:irmamobile/src/prototypes/design_icons.dart';
import 'package:irmamobile/src/prototypes/design_messages.dart';
import 'package:irmamobile/src/prototypes/design_typography.dart';
import 'package:irmamobile/src/prototypes/prototype_26.dart';
import 'package:irmamobile/src/prototypes/schermflow_1.dart';
import 'package:irmamobile/src/prototypes/schermflow_5.dart';
import 'package:irmamobile/src/prototypes/schermflow_wallet.dart';
import 'package:irmamobile/src/screens/change_pin/change_pin_screen.dart';
import 'package:irmamobile/src/screens/enrollment/email_sent_screen.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/introduction.dart';
import 'package:irmamobile/src/screens/help/help_screen.dart';
import 'package:irmamobile/src/screens/history/history_screen.dart';
import 'package:irmamobile/src/screens/reset_pin/reset_pin_screen.dart';
import 'package:irmamobile/src/screens/session/call_info_screen.dart';
import 'package:irmamobile/src/screens/session/session_screen.dart';
import 'package:irmamobile/src/screens/session/widgets/arrow_back_screen.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:irmamobile/src/screens/splash_screen/splash_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class PrototypesScreen extends StatelessWidget {
  static const routeName = "/";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IrmaAppBar(
        title: Text("IRMA Prototypes"),
      ),
      body: Builder(builder: (context) {
        return _buildList(context);
      }),
    );
  }

  Padding _buildList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Schermflows",
                  style: Theme.of(context).textTheme.display1,
                ),
                Text("op basis van UX designs", style: Theme.of(context).textTheme.subhead),
              ],
            ),
          ),
          const Divider(height: 0),
          _buildListItem(context, "Introductie en aanmelden", () {
            startSchermflow1(context);
          }),
          _buildListItem(context, "Gegevens toevoegen", () {
            startSchermflow5(context);
          }),
          _buildListItem(context, "Meerdere gegevenskaarten", () {
            startSchermflowWallet(context);
          }),
          _buildListItem(context, "Pincode veranderen", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChangePinScreen()));
          }),
          _buildListItem(context, "Pincode resetten", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => ResetPinScreen()));
          }),
          _buildListItem(context, "Introductie", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => Introduction()));
          }),
          _buildListItem(context, "Hoofdmenu", () {
            startPrototype26(context);
          }),
          _buildListItem(context, "History", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => HistoryScreen()));
          }),
          _buildListItem(context, "Email sent info screen", () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => EmailSentScreen(email: "john.smith@example.com")));
          }),
          _buildListItem(context, "Disclosure screen", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => SessionScreen()));
          }),
          _buildListItem(context, "Call info screen", () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CallInfoScreen(
                      otherParty: 'requestor',
                    )));
          }),
          _buildListItem(context, "Settings", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => SettingsScreen()));
          }),
          _buildListItem(context, "Help screen", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => HelpScreen()));
          }),
          _buildListItem(context, "Splash screen", () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SplashScreen(),
              ),
            );
          }),
          _buildListItem(context, "Arrow back screen", () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ArrowBack(),
              ),
            );
          }),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Dev experimenten",
                  style: Theme.of(context).textTheme.display1,
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Design previews",
                  style: Theme.of(context).textTheme.display1,
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          _buildListItem(context, "Colors", () {
            startDesignColors(context);
          }),
          _buildListItem(context, "Typography", () {
            startDesignTypography(context);
          }),
          _buildListItem(context, "Icons", () {
            startDesignIcons(context);
          }),
          _buildListItem(context, "Buttons", () {
            startDesignButtons(context);
          }),
          _buildListItem(context, "Fields", () {
            startDesignFields(context);
          }),
          _buildListItem(context, "Bottombar", () {
            startBottombarMessages(context);
          }),
          _buildListItem(context, "Messages", () {
            startDesignMessages(context);
          }),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, String name, void Function() onTap) {
    var itemTextTheme = Theme.of(context).textTheme.body2;
    if (onTap == null) {
      itemTextTheme = itemTextTheme.copyWith(
        color: IrmaTheme.of(context).grayscale60,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: () {
            if (onTap == null) {
              Scaffold.of(context).showSnackBar(const SnackBar(content: Text("Not implemented yet.")));
              return;
            }
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Text(
                    name,
                    style: itemTextTheme,
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                  ),
                ),
                Text(">", style: Theme.of(context).textTheme.body2),
              ],
            ),
          ),
        ),
        const Divider(height: 0),
      ],
    );
  }
}
