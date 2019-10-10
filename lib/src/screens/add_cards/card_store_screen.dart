import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/add_cards/card_info_screen.dart';
import 'package:irmamobile/src/screens/add_cards/widgets/credential.dart';
import 'package:irmamobile/src/screens/add_cards/widgets/credential_group.dart';
import 'package:irmamobile/src/screens/issuance_webview/issuance_webview_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';

class CardStoreScreen extends StatelessWidget {
  static const String routeName = '/store';
  final double _seperatorHeight = 16;

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgets = [
      CredentialGroup(
        title: FlutterI18n.translate(context, 'card_store.personal_data'),
        credentials: <Credential>[
          _buildCredential(context, "Persoonsgegevens", "Gemeente(BRP)", "assets/non-free/irmalogo.png", () {
            _openURL(context, "https://services.nijmegen.nl/irma/gemeente/start");
          }),
          _buildCredential(context, "Contactgegevens", "Privacy by Design Foundation", "assets/non-free/irmalogo.png", () {}),
          _buildCredential(context, "Persoonsgegevens", "iDin", "assets/non-free/irmalogo.png", () {})
        ],
      ),
      SizedBox(
        height: _seperatorHeight,
      ),
      CredentialGroup(
        title: FlutterI18n.translate(context, 'card_store.identity_cards'),
        credentials: <Credential>[
          _buildCredential(context, "Paspoort", "Gemeente(BRP)", "assets/non-free/irmalogo.png", () {}),
          _buildCredential(context, "Rijbewijs", "RDW", "assets/non-free/irmalogo.png", () {}),
          _buildCredential(context, "Identiteitskaart", "Privacy by Design Foundation", "assets/non-free/irmalogo.png", () {})
        ],
      ),
      SizedBox(
        height: _seperatorHeight,
      ),
      CredentialGroup(
        title: FlutterI18n.translate(context, 'card_store.education'),
        credentials: <Credential>[
          _buildCredential(context, "Inloggegevens", "SURF Hoger Onderwijs", "assets/non-free/irmalogo.png", () {}),
          _buildCredential(context, "Inloggegevens", "EduGAIN", "assets/non-free/irmalogo.png", () {}),
          _buildCredential(context, "Diploma's", "DUO", "assets/non-free/irmalogo.png", () {})
        ],
      ),
      SizedBox(
        height: _seperatorHeight,
      ),
      CredentialGroup(
        title: FlutterI18n.translate(context, 'card_store.health'),
        credentials: <Credential>[
          _buildCredential(context, "Zorgregistratiegegevens", "BIG", "assets/non-free/irmalogo.png", () {
            _openURL(context, "https://privacybydesign.foundation/uitgifte/big/");
          }),
          _buildCredential(context, "Zorgregistratiegegevens", "Stichting Nuts Vektis", "assets/non-free/irmalogo.png", () {}),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          FlutterI18n.translate(context, 'card_store.app_bar'),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              FlutterI18n.translate(context, 'card_store.choose'),
              textAlign: TextAlign.left,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Theme(
              child: TextField(
                //onChanged: ,
                decoration: InputDecoration(
                    fillColor: IrmaTheme.of(context).greyscale90,
                    filled: true,
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: () {
                          debugPrint('remove search term');
                        }),
                    hintText: FlutterI18n.translate(context, 'card_store.search'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.zero),
              ),
              // Theme data to control the color of the icons in the search bar when the search bar is active
              data: Theme.of(context).copyWith(
                primaryColor: IrmaTheme.of(context).greyscale40,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 32.0, right: 32.0),
              child: ListView.builder(
                itemCount: widgets.length,
                itemBuilder: (context, index) {
                  return widgets[index];
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredential(
      BuildContext context, String title, String issuer, String iconAsset, VoidCallback onStartIssuane) {
    return Credential(
      icon: Image.asset(iconAsset),
      title: title,
      subTitle: issuer,
      obtained: false,
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CardInfoScreen(title, issuer, iconAsset, onStartIssuane),
            ));
      },
    );
  }

  _openURL(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return IssuanceWebviewScreen(url);
      }),
    );
  }
}
