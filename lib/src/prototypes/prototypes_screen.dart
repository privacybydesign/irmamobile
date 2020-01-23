import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_client_mock.dart';
import 'package:irmamobile/src/prototypes/design_bottombar.dart';
import 'package:irmamobile/src/prototypes/design_buttons.dart';
import 'package:irmamobile/src/prototypes/design_colors.dart';
import 'package:irmamobile/src/prototypes/design_fields.dart';
import 'package:irmamobile/src/prototypes/design_icons.dart';
import 'package:irmamobile/src/prototypes/design_typography.dart';
import 'package:irmamobile/src/prototypes/dev_experiment_1.dart';
import 'package:irmamobile/src/prototypes/dev_experiment_2.dart';
import 'package:irmamobile/src/prototypes/dev_experiment_3.dart';
import 'package:irmamobile/src/prototypes/dev_experiment_4.dart';
import 'package:irmamobile/src/prototypes/prototype_26.dart';
import 'package:irmamobile/src/prototypes/schermflow_1.dart';
import 'package:irmamobile/src/prototypes/schermflow_5.dart';
import 'package:irmamobile/src/prototypes/schermflow_wallet.dart';
import 'package:irmamobile/src/screens/change_pin/change_pin_screen.dart';
import 'package:irmamobile/src/screens/disclosure/disclosure.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/introduction.dart';
import 'package:irmamobile/src/screens/error/error_screen.dart';
import 'package:irmamobile/src/screens/error/no_internet_screen.dart';
import 'package:irmamobile/src/screens/help/help_screen.dart';
import 'package:irmamobile/src/screens/history/history_screen.dart';
import 'package:irmamobile/src/screens/loading/loading_screen.dart';
import 'package:irmamobile/src/screens/reset_pin/reset_pin_screen.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:irmamobile/src/screens/splash_screen/splash_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';

class PrototypesScreen extends StatelessWidget {
  static const routeName = "/";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("IRMA Prototypes"),
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
          _buildListItem(context, "1. Introductie en aanmelden", () {
            startSchermflow1(context);
          }),
          _buildListItem(context, "2. IRMA Account aangemaakt", null),
          _buildListItem(context, "3. Gemeentegegevens opgehaald", null),
          _buildListItem(context, "4. Contactgegevens toevoegen", null),
          _buildListItem(context, "5. Gegevens toevoegen", () {
            startSchermflow5(context);
          }),
          _buildListItem(context, "6. Meerdere gegevenskaarten", () {
            startSchermflowWallet(context);
          }),
          _buildListItem(context, "7. Vrijgeven leeftijd 18+", null),
          _buildListItem(context, "8. Vrijgeven leeftijd 18+ & contactgegevens", null),
          _buildListItem(context, "9. Stemmen Weesperstraat", null),
          _buildListItem(context, "10. Vrijgeven met eerst kaart ophalen", null),
          _buildListItem(context, "11. Pincode resetten", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => ResetPinScreen()));
          }),
          _buildListItem(context, "12. Gegevens bijna niet meer geldig", null),
          _buildListItem(context, "13. Gegevens verouders", null),
          _buildListItem(context, "14. eID kaart toevoegen vanuit IRMA", null),
          _buildListItem(context, "15. eID kaart delen met IRMA", null),
          _buildListItem(context, "16. Uitvraag samenstellen door politie", null),
          _buildListItem(context, "17. Leeftijd 18+ bewijzen via QR-code", null),
          _buildListItem(context, "18. Bevoegdheid politie opvragen", null),
          _buildListItem(context, "19. Rijbewijs toevoegen met ID", null),
          _buildListItem(context, "20. Rijvaardigheid bewijzen via NFC & FaceID", null),
          _buildListItem(context, "21. Leeftijd 21+ bewijzen via NFC & FraceID", null),
          _buildListItem(context, "22. Leeftijd 21+ bewijzen via NFC & Pincode", null),
          _buildListItem(context, "23. ID en rijbewijs landscape", null),
          _buildListItem(context, "24. Pincode veranderen", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChangePinScreen()));
          }),
          _buildListItem(context, "25. Introductie", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => Introduction()));
          }),
          _buildListItem(context, "26. Hoofdmenu", () {
            startPrototype26(context);
          }),
          _buildListItem(context, "27. Loading screen", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoadingScreen()));
          }),
          _buildListItem(context, "28. Error screen", () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ErrorScreen(
                    "Nam vitae hendrerit velit, quis aliquam diam. Donec ut facilisis risus, quis venenatis sapien. Vestibulum elementum euismod quam, sed scelerisque purus vehicula semper. ")));
          }),
          _buildListItem(context, "29. History", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => HistoryScreen()));
          }),
          _buildListItem(context, "30. Disclosure screen", () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => DisclosureScreen(IrmaClientMock().getVerify())));
          }),
          _buildListItem(context, "31. No internet screen", () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => NoInternetScreen(() {
                      print("retry callback");
                    })));
          }),
          _buildListItem(context, "32. Settings", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => SettingsScreen()));
          }),
          _buildListItem(context, "33. Help screen", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => HelpScreen()));
          }),
          _buildListItem(context, "34. Splash screen", () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => SplashScreen()));
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
          _buildListItem(context, "1. IrmaRepository voorbeeld", () {
            startDevExperiment1(context);
          }),
          _buildListItem(context, "2. IrmaRepository Bloc voorbeeld", () {
            startDevExperiment2(context);
          }),
          _buildListItem(context, "3. Update checker", () {
            startDevExperiment3(context);
          }),
          _buildListItem(context, "4. Pin screen", () {
            startDevExperiment4(context);
          }),
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
          _buildListItem(context, "1. Colors", () {
            startDesignColors(context);
          }),
          _buildListItem(context, "2. Typography", () {
            startDesignTypography(context);
          }),
          _buildListItem(context, "3. Icons", () {
            startDesignIcons(context);
          }),
          _buildListItem(context, "4. Buttons", () {
            startDesignButtons(context);
          }),
          _buildListItem(context, "5. Fields", () {
            startDesignFields(context);
          }),
          _buildListItem(context, "7. Bottombar", () {
            startBottombarMessages(context);
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
