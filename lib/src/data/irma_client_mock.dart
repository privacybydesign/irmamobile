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
    description: {'nl': 'My Credential Type mock description'},
    issueUrl: {'nl': 'https://mock.url.nl'},
    isInCredentialStore: true,
    category: {'nl': 'TODO'},
    faqIntro: {'nl': 'TODO'},
    faqPurpose: {'nl': 'TODO'},
    faqContent: {'nl': 'TODO'},
    faqHowto: {'nl': 'TODO'},
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
        name: {'nl': "Naam", 'en': "Name"},
      ),
      "$myCredentialFoo.sex": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Geslacht", 'en': "Sex"},
      ),
      "$myCredentialFoo.birthdate": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Geboren", 'en': "Birthday"},
      ),
      "$myCredentialFoo.address": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Adres", 'en': "Address"},
      ),
      "$myCredentialFoo.bsn": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "BSN", 'en': "BSN"},
      ),
      "$myCredentialFoo.tel": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Telefoon", 'en': "Phone"},
      ),
      "$myCredentialFoo.email": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "E-mail", 'en': "E-mail"},
      ),
      "$myCredentialFoo.filler": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Lorum", 'en': "Lorum"},
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
            ["Amsterdam1", "iDIN1", "DUO1", "Amsterdam2", "iDIN2", "DUO2", "Amsterdam3", "iDIN3", "DUO3"])
        .asyncMap<Credential>((id) => getCredential(id).first)
        .fold<Map<String, Credential>>(<String, Credential>{}, (credentialMap, credential) {
          credentialMap[credential.id] = credential;
          return credentialMap;
        })
        .asStream()
        .map<Credentials>((credentialMap) => Credentials(credentialMap));
  }

  @override
  Stream<IrmaConfiguration> getIrmaConfiguration() {
    return Stream.value(irmaConfiguration);
  }

  @override
  Stream<Credential> getCredential(String id) {
    if (id == "") {
      return Future<Credential>.delayed(Duration(milliseconds: 100), throw CredentialNotFoundException()).asStream();
    }

    Attributes attributes;

    switch (id) {
      case "Amsterdam1":
      case "Amsterdam2":
      case "Amsterdam3":
        attributes = Attributes({
          irmaConfiguration.attributeTypes["$myCredentialFoo.name"]:
              TranslatedValue({'nl': 'Anouk Meijer', 'en': 'Anouk Meijer'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.sex"]:
              TranslatedValue({'nl': 'Vrouwelijk', 'en': 'Female'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.birthdate"]:
              TranslatedValue({'nl': '4 juli 1990', 'en': 'Juli 4th, 1990'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.address"]: TranslatedValue(
              {'nl': 'Pieter Aertszstraat 5\n1073 SH Amsterdam', 'en': 'Pieter Aertszstraat 5\n1073 SH Amsterdam'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.bsn"]:
              TranslatedValue({'nl': '1907.54.629', 'en': '1907.54.629'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.tel"]:
              TranslatedValue({'nl': '06 8723 9064', 'en': '06 8723 9064'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.email"]:
              TranslatedValue({'nl': 'anoukm71@gmail.com', 'en': 'anoukm71@gmail.com'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.filler"]: TranslatedValue({
            'nl':
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec consectetur leo at suscipit egestas. Curabitur eget elementum tellus. Pellentesque viverra semper sapien, vitae convallis eros euismod at. Suspendisse tempus sollicitudin massa ut semper. Phasellus rhoncus sem et iaculis ultricies. In eros dui, fringilla a congue non, fermentum sit amet dui. Proin ligula tortor, scelerisque quis faucibus eget, condimentum non sapien.',
            'en':
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec consectetur leo at suscipit egestas. Curabitur eget elementum tellus. Pellentesque viverra semper sapien, vitae convallis eros euismod at. Suspendisse tempus sollicitudin massa ut semper. Phasellus rhoncus sem et iaculis ultricies. In eros dui, fringilla a congue non, fermentum sit amet dui. Proin ligula tortor, scelerisque quis faucibus eget, condimentum non sapien.'
          }),
        });
        break;
      case "iDIN1":
      case "iDIN2":
      case "iDIN3":
        attributes = Attributes({
          irmaConfiguration.attributeTypes["$myCredentialFoo.name"]:
              TranslatedValue({'nl': 'Anouk Meijer', 'en': 'Anouk Meijer'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.sex"]:
              TranslatedValue({'nl': 'Vrouwelijk', 'en': 'Female'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.birthdate"]:
              TranslatedValue({'nl': '4 juli 1990', 'en': 'Juli 4th, 1990'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.bsn"]:
              TranslatedValue({'nl': '1907.54.629', 'en': '1907.54.629'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.address"]: TranslatedValue(
              {'nl': 'Pieter Aertszstraat 5\n1073 SH Amsterdam', 'en': 'Pieter Aertszstraat 5\n1073 SH Amsterdam'}),
        });
        break;
      default:
        attributes = Attributes({
          irmaConfiguration.attributeTypes["$myCredentialFoo.name"]:
              TranslatedValue({'nl': 'Anouk Meijer', 'en': 'Anouk Meijer'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.sex"]:
              TranslatedValue({'nl': 'Vrouwelijk', 'en': 'Female'}),
          irmaConfiguration.attributeTypes["$myCredentialFoo.birthdate"]:
              TranslatedValue({'nl': '4 juli 1990', 'en': 'Juli 4th, 1990'}),
        });
        break;
    }

    return Future.delayed(
      Duration(milliseconds: 100),
      () => Credential(
        id: id,
        // TODO: realistic value
        // TODO: use irmaConfiguration.issuers[myIssuerId],
        issuer: Issuer(id: id, name: {'nl': id, 'en': id}),
        // TODO: realistic value
        schemeManager: irmaConfiguration.schemeManagers[mySchemeManagerId],
        // TODO: realistic value
        signedOn: DateTime.now(),
        expires: DateTime.now().add(Duration(minutes: 5)),
        attributes: attributes,
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
                name: {'nl': 'Gemeente Amsterdam', 'en': 'Gemeente Amsterdam'},
              ),
              'foobar.duo': Issuer(
                name: {'nl': 'Dienst Uitvoering Onderwijs', 'en': 'Dienst Uitvoering Onderwijs'},
              ),
              'foobar.idin': Issuer(
                name: {'nl': 'iDIN', 'en': 'iDIN'},
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
    _isEnrolledSubject.add(true);
  }

  final BehaviorSubject<bool> lockedSubject = BehaviorSubject<bool>.seeded(false);
  final PublishSubject<bool> _isEnrolledSubject = PublishSubject<bool>();

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

  @override
  Stream<bool> getIsEnrolled() {
    return _isEnrolledSubject.stream;
  }

  @override
  void startSession(String request) {}
}
