import "dart:math";

import "debug_schemes.dart";
import "session/portrait_photo_mock.dart";

class DebugHelper {
  static final _random = Random();
  final DebugSchemes schemes;

  DebugHelper({required this.schemes});

  static String disclosureSessionRequest() {
    return '''
      {
        "@context": "https://irma.app/ld/request/disclosure/v2",
        "disclose": [
          [
            [
              "irma-demo.gemeente.personalData.fullname",
              "irma-demo.gemeente.personalData.initials"
            ],
            [
              "irma-demo.digidproef.personalData.fullname",
              "irma-demo.digidproef.personalData.initials",
              "irma-demo.digidproef.personalData.photo"
            ]
          ]
        ],
        "clientReturnUrl": "tel:+31612345678,1234567"
      }
    ''';
  }

  static String signingSessionRequest() {
    return '''
      {
        "@context": "https://irma.app/ld/request/signature/v2",
        "message": "Ik geef hierbij toestemming aan Partij A om mijn gegevens uit te wisselen met Partij B. Deze toestemming is geldig tot 1 juni 2019.",
        "disclose": [
          [
            [
              "pbdf.sidn-pbdf.irma.pseudonym"
            ]
          ]
        ]
      }
    ''';
  }

  String _issuanceSessionRequest(List<String> credentialsJson) {
    return '''
      {
        "@context": "https://irma.app/ld/request/issuance/v2",
        "credentials": [${credentialsJson.join(", ")}]
      }
    ''';
  }

  String _credentialRequest(
    DebugCredentialType credentialType,
    List<String> attributeValues,
  ) {
    return '''
      {
        "credential": "${credentialType.id}",
        "attributes": {${attributeValues.join(", ")}}
      }
    ''';
  }

  String _randomAttributeValue() {
    const attributeValues = ["lorem", "ipsum"];
    return attributeValues[_random.nextInt(attributeValues.length)];
  }

  Future<String> digidProefIssuanceRequest() async {
    // We assume this credential is present.
    final credentialType = schemes.credentialTypes.firstWhere(
      (type) => type.id == "irma-demo.digidproef.personalData",
    );

    final attributeValues = credentialType.attributes.map((attributeType) {
      final value = attributeType.displayHint == "portraitPhoto"
          ? portraitPhotoMock
          : _randomAttributeValue();
      return '"${attributeType.id}": "$value"';
    }).toList();

    return _issuanceSessionRequest([
      _credentialRequest(credentialType, attributeValues),
    ]);
  }

  Future<String> randomIssuanceRequest(int amount) async {
    final credentialTypes = schemes.credentialTypes
        .where((ct) => ct.schemeManagerId == "irma-demo")
        .toList();

    final credentialsJson = List<String>.generate(amount, (int i) {
      final credentialType =
          credentialTypes[_random.nextInt(credentialTypes.length)];
      final attributeValues = credentialType.attributes
          .map(
            (attributeType) =>
                '"${attributeType.id}": "${_randomAttributeValue()}"',
          )
          .toList();

      return _credentialRequest(credentialType, attributeValues);
    });

    return _issuanceSessionRequest(credentialsJson);
  }
}
