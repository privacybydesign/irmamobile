import 'package:irmamobile/src/data/irma_client.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/authentication_result.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:irmamobile/src/models/version_information.dart';
import 'package:rxdart/rxdart.dart';
import 'package:version/version.dart';

class CredentialNotFoundException implements Exception {}

class IrmaClientMock implements IrmaClient {
  final bool versionUpdateAvailable;
  final bool versionUpdateRequired;

  static const String mySchemeManagerId = "mySchemeManager";
  static final SchemeManager mySchemeManager = SchemeManager(
    id: mySchemeManagerId,
    name: {'nl': "My Scheme Manager"},
    description: {'nl': "Mocked scheme manager using fake data to render the app."},
  );
  static const String myIssuerId = "$mySchemeManagerId.myIssuer";
  static final Issuer myIssuer = Issuer(
    id: myIssuerId,
    shortName: {'nl': "MI"},
    name: {'nl': "My Issuer"},
  );
  static const String myCredentialTypeId = "$myIssuerId.myCredentialType";
  static final CredentialType myCredentialType = CredentialType(
    id: myCredentialTypeId,
    name: {'nl': "MyCredentialType"},
    shortName: {'nl': "MCT"},
    description: {'nl': 'My Credential Type'},
    schemeManagerId: mySchemeManagerId,
    issuerId: myIssuerId,
  );

  static const String myCredentialFoo = "$myIssuerId.myCredentialFoo";

  final IrmaConfiguration irmaConfiguration = IrmaConfiguration(
    schemeManagers: {mySchemeManagerId: mySchemeManager},
    issuers: {
      myIssuerId: myIssuer,
    },
    attributeTypes: {
      "$myCredentialFoo.name": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 1,
        name: {'nl': "Name"},
      ),
      "$myCredentialFoo.birthdate": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Geboortedatum"},
      ),
      "$myCredentialFoo.email": AttributeType(
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
    return Stream.fromIterable(
            ["amsterdam", "idin", "duo", "amsterdam2", "idin2", "duo2", "amsterdam3", "idin3", "duo3"])
        .asyncMap<Credential>((id) => getCredential(id).first)
        .fold<Map<String, Credential>>(<String, Credential>{}, (credentialMap, credential) {
          credentialMap[credential.id] = credential;
          return credentialMap;
        })
        .asStream()
        .map<Credentials>((credentialMap) => Credentials(credentialMap));
  }

  @override
  Stream<Credential> getCredential(String id) {
    if (id == "") {
      return Future<Credential>.delayed(Duration(milliseconds: 100), throw CredentialNotFoundException()).asStream();
    }
    return Future.delayed(
      Duration(milliseconds: 100),
      () => Credential(
        id: id,
        // TODO: realistic value
        // TODO: use irmaConfiguration.issuers[myIssuerId],
        issuer: Issuer(id: id, name: {'nl': id}),
        // TODO: realistic value
        schemeManager: irmaConfiguration.schemeManagers[mySchemeManagerId],
        // TODO: realistic value
        signedOn: DateTime.now(),
        expires: DateTime.now().add(Duration(minutes: 5)),
        attributes: Attributes({
          irmaConfiguration.attributeTypes["$myCredentialFoo.name"]:
              TranslatedValue({'nl': 'Anouk Meijer', 'en': 'Anouk Meijer'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.birthdate"]:
              TranslatedValue({'nl': '4 juli 1990', 'en': 'Juli 4th, 1990'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.email"]:
              TranslatedValue({'nl': 'anouk.meijer@gmail.com', 'en': 'anouk.meijer@gmail.com'}),
        }),
        hash: "foobar",
        // TODO: realistic value
        credentialType: myCredentialType,
      ),
    ).asStream();
  }

  @override
  Stream<Map<String, Issuer>> getIssuers() {
    return Future.delayed(
        Duration(seconds: 1),
        () => {
              // TODO: use legit demo names
              'foobar.amsterdam': Issuer(
                name: {'nl': 'Gemeente Amsterdam'},
              ),
              'foobar.duo': Issuer(
                name: {'nl': 'Dienst Uitvoering Onderwijs'},
              ),
              'foobar.idin': Issuer(
                name: {'nl': 'iDIN'},
              ),
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

  final BehaviorSubject<bool> lockedSubject = BehaviorSubject<bool>.seeded(false);

  @override
  void lock() {
    lockedSubject.add(true);
  }

  @override
  Future<AuthenticationResult> unlock(String pin) async {
    if (pin == "12345") {
      lockedSubject.add(false);
      return AuthenticationResultSuccess();
    }
    return AuthenticationResultFailed(
      blockedDuration: 0,
      remainingAttempts: 2,
    );
  }

  @override
  Stream<bool> getLocked() {
    return lockedSubject.stream;
  }
}
