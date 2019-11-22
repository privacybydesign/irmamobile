import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/add_card_email/add_email_card_screen.dart';
import 'package:irmamobile/src/screens/add_cards/card_info_screen.dart';
import 'package:irmamobile/src/screens/issuance_webview/issuance_webview_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/card_suggestion.dart';
import 'package:irmamobile/src/widgets/card_suggestion_group.dart';

class CardStoreScreen extends StatelessWidget {
  static const String routeName = '/store';
  final double _seperatorHeight = 16;

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgets = [
      CardSuggestionGroup(
        title: FlutterI18n.translate(context, 'card_store.popular'),
        credentials: <CardSuggestion>[
          _buildCardSuggestion(context, "Persoonsgegevens", "Gemeente(BRP)", "assets/non-free/irmalogo.png", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CardInfoScreen(
                  "Persoonsgegevens",
                  "Gemeente(BRP)",
                  "assets/non-free/irmalogo.png",
                  () {
                    _openURL(context, "https://services.nijmegen.nl/irma/gemeente/start");
                  },
                ),
              ),
            );
          }),
          _buildCardSuggestion(context, "E-mail", "Privacy by Design Foundation", "assets/non-free/irmalogo.png", () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddEmailCardScreen(
                  "https://privacybydesign.foundation/tomcat/irma_email_issuer/api//send-email-token",
                ),
              ),
            );
          }),
          _buildCardSuggestion(context, "Persoonsgegevens", "iDin", "assets/non-free/irmalogo.png", null)
        ],
      ),
      SizedBox(
        height: _seperatorHeight,
      ),
      CardSuggestionGroup(
        title: FlutterI18n.translate(context, 'card_store.identity_cards'),
        credentials: <CardSuggestion>[
          _buildCardSuggestion(context, "Paspoort", "Gemeente(BRP)", "assets/non-free/irmalogo.png", null),
          _buildCardSuggestion(context, "Rijbewijs", "RDW", "assets/non-free/irmalogo.png", null),
          _buildCardSuggestion(context, "Identiteitskaart", "Privacy by Design Foundation", "assets/non-free/irmalogo.png", null)
        ],
      ),
      SizedBox(
        height: _seperatorHeight,
      ),
      CardSuggestionGroup(
        title: FlutterI18n.translate(context, 'card_store.education'),
        credentials: <CardSuggestion>[
          _buildCardSuggestion(context, "Inloggegevens", "SURF Hoger Onderwijs", "assets/non-free/irmalogo.png", null),
          _buildCardSuggestion(context, "Inloggegevens", "EduGAIN", "assets/non-free/irmalogo.png", null),
          _buildCardSuggestion(context, "Diploma's", "DUO", "assets/non-free/irmalogo.png", null)
        ],
      ),
      SizedBox(
        height: _seperatorHeight,
      ),
      CardSuggestionGroup(
        title: FlutterI18n.translate(context, 'card_store.health'),
        credentials: <CardSuggestion>[
          CardSuggestion(
              icon: Image.asset("assets/non-free/irmalogo.png"),
              title: "Zorgregistratiegegevens",
              subTitle: "BIG",
              obtained: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CardInfoScreen(
                      "Zorgregistratiegegevens",
                      "BIG",
                      "assets/non-free/irmalogo.png",
                      () {
                        _openURL(context, "https://privacybydesign.foundation/uitgifte/big/");
                      },
                    ),
                  ),
                );
              }),
          CardSuggestion(
            icon: Image.asset("assets/non-free/irmalogo.png"),
            title: "Zorgregistratiegegevens",
            subTitle: "Stichting Nuts Vektis",
            obtained: false,
            onTap: null,
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          FlutterI18n.translate(context, 'card_store.app_bar'),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
                top: (IrmaTheme.of(context).spacing / 4) * 5,
                left: IrmaTheme.of(context).spacing,
                bottom: IrmaTheme.of(context).spacing),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                FlutterI18n.translate(context, 'card_store.choose'),
                style: IrmaTheme.of(context).textTheme.body1,
              ),
            ),
          ),
          // // Search
          // Padding(
          //   padding: EdgeInsets.all(IrmaTheme.of(context).spacing),
          //   child: Theme(
          //     // Theme data to control the color of the icons in the search bar when the search bar is active
          //     data: Theme.of(context).copyWith(
          //       primaryColor: IrmaTheme.of(context).grayscale40,
          //     ),
          //     child: TextField(
          //       //onChanged: ,
          //       decoration: InputDecoration(
          //           fillColor: IrmaTheme.of(context).grayscale90,
          //           filled: true,
          //           prefixIcon: Icon(IrmaIcons.search),
          //           suffixIcon: IconButton(
          //               icon: Icon(Icons.cancel),
          //               onPressed: () {
          //                 debugPrint('remove search term');
          //               }),
          //           hintText: FlutterI18n.translate(context, 'card_store.search'),
          //           border: OutlineInputBorder(
          //             borderRadius: BorderRadius.circular(10),
          //             borderSide: BorderSide.none,
          //           ),
          //           contentPadding: EdgeInsets.zero),
          //     ),
          //   ),
          // ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
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

  CardSuggestion _buildCardSuggestion(
      BuildContext context, String title, String issuer, String iconAsset, VoidCallback onTap) {
    return CardSuggestion(
      icon: Image.asset(iconAsset),
      title: title,
      subTitle: issuer,
      obtained: false,
      onTap: onTap,
    );
  }

  void _openURL(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return IssuanceWebviewScreen(url);
      }),
    );
  }
}
