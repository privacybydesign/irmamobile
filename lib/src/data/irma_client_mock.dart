import 'package:irmamobile/src/data/irma_client.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:irmamobile/src/models/version_information.dart';
import 'package:version/version.dart';

class CredentialNotFoundException implements Exception {}

class IrmaClientMock implements IrmaClient {
  final bool versionUpdateAvailable;
  final bool versionUpdateRequired;

  static final String mySchemeManagerId = "mySchemeManager";
  static final SchemeManager mySchemeManager = SchemeManager(
    id: mySchemeManagerId,
    name: {'nl': "My Scheme Manager"},
    description: {'nl': "Mocked scheme manager using fake data to render the app."},
  );
  static final String myIssuerId = mySchemeManagerId + ".myIssuer";
  static final myIssuer = Issuer(
    id: myIssuerId,
    shortName: {'nl': "MI"},
    name: {'nl': "My Issuer"},
  );
  static final String myCredentialTypeId = myIssuerId + ".myCredentialType";
  static final myCredentialType = CredentialType(
    id: myCredentialTypeId,
    name: {'nl': "MyCredentialType"},
    shortName: {'nl': "MCT"},
    description: {'nl': 'My Credential Type'},
    schemeManagerId: mySchemeManagerId,
    issuerId: myIssuerId,
  );

  static final String myCredentialFoo = myIssuerId + ".myCredentialFoo";

  final IrmaConfiguration irmaConfiguration = IrmaConfiguration(
    schemeManagers: {mySchemeManagerId: mySchemeManager},
    issuers: {
      myIssuerId: myIssuer,
    },
    attributeTypes: {
      myCredentialFoo + ".name": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 1,
        name: {'nl': "Name"},
      ),
      myCredentialFoo + ".birthdate": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Geboortedatum"},
      ),
      myCredentialFoo + ".email": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 3,
        name: {'nl': "E-Mail"},
      ),
    },
  );

  IrmaClientMock({
    this.versionUpdateAvailable = false,
    this.versionUpdateRequired = false,
  }) : assert(versionUpdateRequired == false || versionUpdateAvailable == true);

  @override
  Stream<Credentials> getCredentials() {
    return getCredential(myCredentialFoo).map<Credentials>(
      (credential) => Credentials({
        credential.id: credential,
      }),
    );
  }

  @override
  Stream<Credential> getCredential(String id) {
    if (id != myCredentialFoo) {
      return Future.delayed(Duration(seconds: 1), throw CredentialNotFoundException()).asStream();
    }
    return Future.delayed(
      Duration(seconds: 1),
      () => Credential(
        id: myCredentialFoo, // TODO: realistic value
        issuer: irmaConfiguration.issuers[myIssuerId], // TODO: realistic value
        schemeManager: irmaConfiguration.schemeManagers[mySchemeManagerId], // TODO: realistic value
        signedOn: DateTime.now(),
        expires: DateTime.now().add(Duration(minutes: 5)),
        attributes: Attributes({
          irmaConfiguration.attributeTypes[myCredentialFoo + ".name"]: TranslatedValue({'nl': 'Anouk Meijer'}),
          irmaConfiguration.attributeTypes[myCredentialFoo + ".birthdate"]: TranslatedValue({'nl': '4 juli 1990'}),
          irmaConfiguration.attributeTypes[myCredentialFoo + ".email"]:
              TranslatedValue({'nl': 'anouk.meijer@gmail.com'}),
        }),
        hash: "foobar", // TODO: realistic value
        credentialType: myCredentialType,
      ),
    ).asStream();
  }

  @override
  Stream<Map<String, Issuer>> getIssuers() {
    return Future.delayed(
        Duration(seconds: 1),
        () => {
              // // TODO: use legit demo names
              // 'foobar.amsterdam': Issuer(
              //   name: {'nl': 'Gemeente Amsterdam'},
              //   // color: Colors.white,
              //   // backgroundColor: Color(0xffec0000),
              //   // backgroundImageFilename: 'amsterdam.png',
              // ),
              // 'foobar.duo': Issuer(
              //   name: {'nl': 'Dienst Uitvoering Onderwijs'},
              //   // color: Colors.white,
              //   // backgroundColor: Color(0xff82a2b9),
              //   // backgroundImageFilename: 'duo.png',
              // ),
              // 'foobar.idin': Issuer(
              //   name: {'nl': 'iDIN'},
              //   // color: Color(0xff424242), // darkgrey
              //   // backgroundColor: Color(0xff4ca9d6),
              //   // backgroundImageFilename: 'idin.png',
              // ),
              myIssuerId: myIssuer,
            }).asStream();
  }

  @override
  Stream<VersionInformation> getVersionInformation() {
    final currentVersion = Version.parse("1.0.0");
    return Future.delayed(
      Duration(milliseconds: versionUpdateRequired ? 2000 : 300),
      () => VersionInformation(
        availableVersion: versionUpdateAvailable ? Version.parse("1.1.1") : currentVersion,
        requiredVersion: versionUpdateRequired ? Version.parse("1.1.0") : currentVersion,
        currentVersion: currentVersion,
      ),
    ).asStream();
  }

  @override
  void enroll({String email, String pin, String language}) {
    // TODO
    throw Exception("Unimplemented");
  }
}
