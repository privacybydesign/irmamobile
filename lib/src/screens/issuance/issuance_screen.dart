import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/issuance/widgets/credential.dart';
import 'package:irmamobile/src/screens/issuance/widgets/credential_group.dart';
import 'package:irmamobile/src/screens/issuance_webview/issuance_webview_screen.dart';

class IssuanceScreen extends StatelessWidget {
  static const String routeName = "/issuance";

  const IssuanceScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          FlutterI18n.translate(context, "issuance.title"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                FlutterI18n.translate(context, "issuance.header"),
              ),
              SizedBox(
                height: 8.0,
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: FlutterI18n.translate(context, "issuance.hint_search"),
                      ),
                    ),
                  ),
                  Icon(Icons.search),
                ],
              ),
              SizedBox(
                height: 16.0,
              ),
              CredentialGroup(
                title: "Persoonsgegevens",
                credentials: <Credential>[
                  Credential(
                    icon: Icon(Icons.person),
                    title: "Persoonsgegevens",
                    subTitle: "Gemeente(BRP)",
                    obtained: false,
                    onTap: () {
                      _openURL(context, "https://services.nijmegen.nl/irma/gemeente/start");
                    },
                  ),
                  Credential(
                    icon: Icon(Icons.person),
                    title: "Contactgegevens",
                    subTitle: "IRMA Privacy by design",
                    obtained: false,
                    onTap: () {
                      _openURL(context, "https://services.nijmegen.nl/irma/gemeente/start");
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 16.0,
              ),
              CredentialGroup(
                title: "Identiteitsbewijzen",
                credentials: <Credential>[
                  Credential(
                    icon: Icon(Icons.person),
                    title: "Paspoort",
                    subTitle: "Gemeente(BRP)",
                    obtained: false,
                    onTap: () {
                      _openURL(context, "https://services.nijmegen.nl/irma/gemeente/start");
                    },
                  ),
                  Credential(
                    icon: Icon(Icons.person),
                    title: "Identiteitskaart",
                    subTitle: "IRMA Privacy by design",
                    obtained: false,
                    onTap: () {
                      _openURL(context, "https://services.nijmegen.nl/irma/gemeente/start");
                    },
                  ),
                  Credential(
                    icon: Icon(Icons.person),
                    title: "Rijbewijs",
                    subTitle: "RDW",
                    obtained: false,
                    onTap: () {
                      _openURL(context, "https://services.nijmegen.nl/irma/gemeente/start");
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 16.0,
              ),
              CredentialGroup(
                title: "Onderwijs",
                credentials: <Credential>[
                  Credential(
                    icon: Icon(Icons.person),
                    title: "Inloggegevens",
                    subTitle: "SURF Hoger onderwijs",
                    obtained: false,
                    onTap: () {
                      _openURL(context, "https://services.nijmegen.nl/irma/gemeente/start");
                    },
                  ),
                  Credential(
                    icon: Icon(Icons.person),
                    title: "Inloggegevens",
                    subTitle: "EduGAIN",
                    obtained: false,
                    onTap: () {
                      _openURL(context, "https://services.nijmegen.nl/irma/gemeente/start");
                    },
                  ),
                  Credential(
                    icon: Icon(Icons.person),
                    title: "Diploma's",
                    subTitle: "DUI",
                    obtained: false,
                    onTap: () {
                      _openURL(context, "https://services.nijmegen.nl/irma/gemeente/start");
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 16.0,
              ),
              CredentialGroup(
                title: "Zorg",
                credentials: <Credential>[
                  Credential(
                    icon: Icon(Icons.person),
                    title: "Zorgregistratiegegevens",
                    subTitle: "BIG",
                    obtained: false,
                    onTap: () {
                      _openURL(context, "https://privacybydesign.foundation/uitgifte/big/");
                    },
                  ),
                  Credential(
                    icon: Icon(Icons.person),
                    title: "Zorgregistratiegegevens",
                    subTitle: "Stichting Nuts Vektis",
                    obtained: false,
                    onTap: () {
                      _openURL(context, "https://services.nijmegen.nl/irma/gemeente/start");
                    },
                  ),
                ],
              ),
              ListTile(
                leading: Icon(Icons.email),
                title: Text(
                  "Laad email attribuut",
                ),
                onTap: () {
                  _openURL(context, "https://privacybydesign.foundation/uitgifte/email/");
                },
              ),
              ListTile(
                leading: Icon(Icons.phone),
                title: Text(
                  "Laad mobiel nummer attribuut",
                ),
                onTap: () {
                  _openURL(context, "https://privacybydesign.foundation/uitgifte/telefoonnummer/");
                },
              ),
              ListTile(
                leading: Icon(Icons.fastfood),
                title: Text(
                  "Laad attributen vanuit Facebook",
                ),
                onTap: () {
                  _openURL(context, "https://privacybydesign.foundation/uitgifte/social/facebook/");
                },
              ),
              ListTile(
                leading: Icon(Icons.fastfood),
                title: Text(
                  "Laad attributen vanuit Twitter",
                ),
                onTap: () {
                  _openURL(context, "https://privacybydesign.foundation/uitgifte/social/twitter/");
                },
              ),
              ListTile(
                leading: Icon(Icons.fastfood),
                title: Text(
                  "Laad attributen vanuit BIG",
                ),
                onTap: () {
                  _openURL(context, "https://privacybydesign.foundation/uitgifte/big/");
                },
              ),
            ],
          ),
        ),
      ),
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
