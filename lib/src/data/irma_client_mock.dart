import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/data/irma_client.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/authentication_result.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/disclosed_attribute.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/log.dart';
import 'package:irmamobile/src/models/preferences.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:irmamobile/src/models/verifier.dart';
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
  static const String myIssuerId = "myIssuer";
  static const String myFullIssuerId = "$mySchemeManagerId.$myIssuerId";
  static final Issuer myIssuer = Issuer(
    id: myIssuerId,
    schemeManagerId: mySchemeManagerId,
    shortName: {'nl': "MI", 'en': "MI"},
    name: {'nl': "My Issuer", 'en': "My Issuer"},
  );
  static const String myCredentialTypeId = "myCredentialType";
  static const String myFullCredentialTypeId = "$myFullIssuerId.$myCredentialTypeId";
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

  static const String myCredentialFoo = "myCredentialFoo";
  static const String myFullCredentialFoo = "$myIssuerId.$myCredentialFoo";

  final IrmaConfiguration irmaConfiguration = IrmaConfiguration(
    schemeManagers: {mySchemeManagerId: mySchemeManager},
    issuers: {
      myFullIssuerId: myIssuer,
    },
    attributeTypes: {
      "$myFullCredentialFoo.name": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 1,
        name: {'nl': "Naam", 'en': "Name"},
      ),
      "$myFullCredentialFoo.sex": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Geslacht", 'en': "Sex"},
      ),
      "$myFullCredentialFoo.birthdate": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Geboren", 'en': "Birthday"},
      ),
      "$myFullCredentialFoo.address": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Adres", 'en': "Address"},
      ),
      "$myFullCredentialFoo.residence": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Woonplaats", 'en': "Residence"},
      ),
      "$myFullCredentialFoo.postcode": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Postcode", 'en': "Postcode"},
      ),
      "$myFullCredentialFoo.bsn": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "BSN", 'en': "BSN"},
      ),
      "$myFullCredentialFoo.tel": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Telefoon", 'en': "Phone"},
      ),
      "$myFullCredentialFoo.email": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "E-mail", 'en': "E-mail"},
      ),
      "$myFullCredentialFoo.filler": AttributeType(
        schemeManagerId: mySchemeManagerId,
        issuerId: myIssuerId,
        credentialTypeId: myCredentialFoo,
        displayIndex: 2,
        name: {'nl': "Lorum", 'en': "Lorum"},
      ),
    },
    credentialTypes: {
      myCredentialTypeId: myCredentialType,
    },
  );

  static List<String> loadedCredentialIds = [
    "Amsterdam1",
    "iDIN1",
    "DUO1",
    "Amsterdam2",
    "iDIN2",
    "DUO2",
    "Amsterdam3",
    "iDIN3",
    "DUO3"
  ];

  IrmaClientMock({
    this.versionUpdateAvailable = false,
    this.versionUpdateRequired = false,
  }) : assert(versionUpdateRequired == false || versionUpdateAvailable == true);

  @override
  Stream<Credentials> getCredentials() {
    return Stream.fromIterable(loadedCredentialIds)
        .asyncMap<Credential>((id) => getCredential(id).first)
        .fold<Map<String, Credential>>(<String, Credential>{}, (credentialMap, credential) {
          credentialMap[credential.id] = credential;
          return credentialMap;
        })
        .asStream()
        .map<Credentials>((credentialMap) => Credentials(credentialMap));
  }

  List<List<VerifierCredential>> getVerify() {
    return [
      [
        VerifierCredential(
          issuer: 'Rijksoverheid',
          attributes: Attributes({
            irmaConfiguration.attributeTypes["$myFullCredentialFoo.name"]:
                TranslatedValue({'nl': 'Anouk Meijer', 'en': 'Anouk Meijer'}),
            irmaConfiguration.attributeTypes["$myFullCredentialFoo.sex"]:
                TranslatedValue({'nl': 'Vrouwelijk', 'en': 'Female'}),
            irmaConfiguration.attributeTypes["$myFullCredentialFoo.birthdate"]:
                TranslatedValue({'nl': 'Ouder dan 18', 'en': 'Older than 18'}),
          }),
        )
      ],
      [
        VerifierCredential(
          issuer: 'Gemeente Almere',
          attributes: Attributes({
            irmaConfiguration.attributeTypes["$myFullCredentialFoo.address"]:
                TranslatedValue({'nl': 'Pieter Aertszstraat 5', 'en': 'Pieter Aertszstraat 5'}),
            irmaConfiguration.attributeTypes["$myFullCredentialFoo.postcode"]:
                TranslatedValue({'nl': '1073 SH', 'en': '1073 SH'}),
            irmaConfiguration.attributeTypes["$myFullCredentialFoo.residence"]:
                TranslatedValue({'nl': 'Amsterdam', 'en': 'Amsterdam'}),
          }),
        ),
        VerifierCredential(
          issuer: 'Rabobank',
          attributes: Attributes({
            irmaConfiguration.attributeTypes["$myFullCredentialFoo.address"]:
                TranslatedValue({'nl': 'Pieter Aertszstraat 5', 'en': 'Pieter Aertszstraat 5'}),
            irmaConfiguration.attributeTypes["$myFullCredentialFoo.postcode"]:
                TranslatedValue({'nl': '1073 SH', 'en': '1073 SH'}),
            irmaConfiguration.attributeTypes["$myFullCredentialFoo.residence"]:
                TranslatedValue({'nl': 'Amsterdam', 'en': 'Amsterdam'}),
          }),
        )
      ],
      [
        VerifierCredential(
          issuer: 'Privacy by Design',
          attributes: Attributes({
            irmaConfiguration.attributeTypes["$myFullCredentialFoo.email"]:
                TranslatedValue({'nl': 'anoukm71@gmail.com', 'en': 'anoukm71@gmail.com'}),
          }),
        ),
        VerifierCredential(
          issuer: 'Xs4all',
          attributes: Attributes({
            irmaConfiguration.attributeTypes["$myFullCredentialFoo.email"]:
                TranslatedValue({'nl': 'anoukm.meijer@xs4all.nl', 'en': 'anoukm.meijer@xs4all.nl'}),
          }),
        ),
        VerifierCredential(
          issuer: 'Ziggo',
          attributes: Attributes({
            irmaConfiguration.attributeTypes["$myFullCredentialFoo.email"]:
                TranslatedValue({'nl': 'ameijer@ziggo.com', 'en': 'ameijer@ziggo.com'}),
          }),
        )
      ]
    ];
  }

  @override
  Stream<IrmaConfiguration> getIrmaConfiguration() {
    return Stream.value(irmaConfiguration);
  }

  @override
  Stream<Credential> getCredential(String id) {
    if (loadedCredentialIds.contains(id) == false) {
      return Future<Credential>.delayed(const Duration(milliseconds: 100), throw CredentialNotFoundException()).asStream();
    }

    Attributes attributes;

    switch (id) {
      case "Amsterdam1":
      case "Amsterdam2":
      case "Amsterdam3":
        attributes = Attributes({
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.name"]:
              TranslatedValue({'nl': 'Anouk Meijer', 'en': 'Anouk Meijer'}),
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.sex"]:
              TranslatedValue({'nl': 'Vrouwelijk', 'en': 'Female'}),
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.birthdate"]:
              TranslatedValue({'nl': '4 juli 1990', 'en': 'Juli 4th, 1990'}),
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.address"]: TranslatedValue(
              {'nl': 'Pieter Aertszstraat 5\n1073 SH Amsterdam', 'en': 'Pieter Aertszstraat 5\n1073 SH Amsterdam'}),
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.bsn"]:
              TranslatedValue({'nl': '1907.54.629', 'en': '1907.54.629'}),
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.tel"]:
              TranslatedValue({'nl': '06 8723 9064', 'en': '06 8723 9064'}),
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.email"]:
              TranslatedValue({'nl': 'anoukm71@gmail.com', 'en': 'anoukm71@gmail.com'}),
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.filler"]: TranslatedValue({
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
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.name"]:
              TranslatedValue({'nl': 'Anouk Meijer', 'en': 'Anouk Meijer'}),
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.sex"]:
              TranslatedValue({'nl': 'Vrouwelijk', 'en': 'Female'}),
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.birthdate"]:
              TranslatedValue({'nl': '4 juli 1990', 'en': 'Juli 4th, 1990'}),
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.bsn"]:
              TranslatedValue({'nl': '1907.54.629', 'en': '1907.54.629'}),
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.address"]: TranslatedValue(
              {'nl': 'Pieter Aertszstraat 5\n1073 SH Amsterdam', 'en': 'Pieter Aertszstraat 5\n1073 SH Amsterdam'}),
        });
        break;
      default:
        attributes = Attributes({
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.name"]:
              TranslatedValue({'nl': 'Anouk Meijer', 'en': 'Anouk Meijer'}),
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.sex"]:
              TranslatedValue({'nl': 'Vrouwelijk', 'en': 'Female'}),
          irmaConfiguration.attributeTypes["$myFullCredentialFoo.birthdate"]:
              TranslatedValue({'nl': '4 juli 1990', 'en': 'Juli 4th, 1990'}),
        });
        break;
    }

    return Future.delayed(
      const Duration(milliseconds: 100),
      () => Credential(
        id: id,
        // TODO: realistic value
        // TODO: use irmaConfiguration.issuers[myIssuerId],
        issuer: Issuer(id: id, name: {'nl': id, 'en': id}),
        // TODO: realistic value
        schemeManager: irmaConfiguration.schemeManagers[mySchemeManagerId],
        // TODO: realistic value
        signedOn: DateTime.now(),
        expires: DateTime.now().add(const Duration(minutes: 5)),
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
        const Duration(seconds: 1),
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

  Preferences _current_prefs = Preferences(enableCrashReporting: true, qrScannerOnStartup: false);
  final BehaviorSubject<Preferences> _preferencesStream =
      BehaviorSubject<Preferences>.seeded(const Preferences(enableCrashReporting: true, qrScannerOnStartup: false));

  @override
  Stream<Preferences> getPreferences() {
    return _preferencesStream.stream;
  }

  @override
  void setCrashReportingPreference({@required bool value}) {
    final newPrefs = Preferences(enableCrashReporting: value, qrScannerOnStartup: _current_prefs.qrScannerOnStartup);

    _current_prefs = newPrefs;

    _preferencesStream.add(_current_prefs);
  }

  @override
  void setQrScannerOnStartupPreference({@required bool value}) {
    final newPrefs = Preferences(enableCrashReporting: _current_prefs.enableCrashReporting, qrScannerOnStartup: value);

    _current_prefs = newPrefs;

    _preferencesStream.add(_current_prefs);
  }

  @override
  void deleteAllCredentials() {
    loadedCredentialIds.clear();
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

  @override
  Stream<List<Log>> loadLogs(int before, int max) {
    return Future<List<Log>>.delayed(const Duration(seconds: 1), () {
      return List.generate(
        max,
        (i) {
          if (i % 4 == 0) {
            return Log(
              id: 1,
              serverName: "mock",
              time: DateTime.now(),
              type: "issuing",
              issuedCredentials: Credentials({
                "": Credential(
                  id: "id",
                  issuer: Issuer(id: "id", name: {'nl': "mock issuer", 'en': "mock issuer"}),
                  schemeManager: SchemeManager(
                    id: "pbdf",
                    name: {'nl': "My Scheme Manager"},
                    description: {'nl': "Mocked scheme manager using fake data to render the app."},
                  ),
                  attributes: Attributes({}),
                  signedOn: DateTime.now(),
                  expires: DateTime.now().add(const Duration(minutes: 5)),
                  hash: "foobar",
                  credentialType: CredentialType(),
                )
              }),
            );
          } else if (i % 3 == 0) {
            return Log(
              id: 1,
              serverName: "mock",
              time: DateTime.now(),
              type: "removal",
              removedCredentials: {"mock card": "mock card"},
            );
          } else if (i % 2 == 0) {
            return Log(
              id: 1,
              serverName: "mock",
              time: DateTime.now(),
              type: "disclosing",
              disclosedAttributes: [
                DisclosedAttribute(
                    identifier: "mock", issuanceTime: DateTime.now(), rawValue: "mock", status: "mock", value: "mock")
              ],
            );
          } else {
            return Log(
              id: 1,
              serverName: "mock",
              time: DateTime.now(),
              type: "signing",
              signedMessage: "mock message",
            );
          }
        },
      );
    }).asStream();
  }
}
