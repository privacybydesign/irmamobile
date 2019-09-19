import 'package:flutter/material.dart';
import 'package:irmamobile/src/prototypes/dev_experiment_1.dart';
import 'package:irmamobile/src/prototypes/dev_experiment_2.dart';
import 'package:irmamobile/src/prototypes/dev_experiment_3.dart';
import 'package:irmamobile/src/prototypes/schermflow_1.dart';
import 'package:irmamobile/src/prototypes/schermflow_5.dart';
import 'package:irmamobile/src/prototypes/schermflow_wallet.dart';

class PrototypesScreen extends StatelessWidget {
  static final routeName = "/";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          Divider(height: 0),
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
          _buildListItem(context, "11. Pincode resetten", null),
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
          SizedBox(height: 12),
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
          Divider(height: 0),
          _buildListItem(context, "1. IrmaRepository voorbeeld", () {
            startDevExperiment1(context);
          }),
          _buildListItem(context, "2. IrmaRepository Bloc voorbeeld", () {
            startDevExperiment2(context);
          }),
          _buildListItem(context, "3. Update checker", () {
            startDevExperiment3(context);
          }),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, String name, void Function() onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  name,
                  style: Theme.of(context).textTheme.body2,
                ),
                Text(">", style: Theme.of(context).textTheme.body2),
              ],
            ),
          ),
          onTap: () {
            if (onTap == null) {
              Scaffold.of(context).showSnackBar(new SnackBar(content: new Text("Not implemented yet.")));
              return;
            }
            onTap();
          },
        ),
        Divider(height: 0),
      ],
    );
  }
}
