import 'dart:math';

import 'package:collection/collection.dart';

import '../../models/irma_configuration.dart';
import 'session/portrait_photo_mock.dart';

class DebugHelper {
  static final _random = Random();
  final IrmaConfiguration irmaConfig;

  DebugHelper({required this.irmaConfig});

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

  Map<String, List<AttributeType>> _attributeTypesByCredentialType(IrmaConfiguration irmaConfiguration) {
    return groupBy<AttributeType, String>(
      irmaConfiguration.attributeTypes.values,
      (attributeType) => attributeType.fullCredentialId,
    );
  }

  String _credentialRequest(CredentialType credentialType, attributeValues) {
    return '''
      {
        "credential": "${credentialType.fullId}",
        "attributes": {${attributeValues.join(", ")}}
      }
    ''';
  }

  String _randomAttributeValue() {
    const attributeValues = ['lorem', 'ipsum'];
    return attributeValues[_random.nextInt(attributeValues.length)];
  }

  Future<String> digidProefIssuanceRequest() async {
    const credentialTypeId = 'irma-demo.digidproef.personalData'; // We assume this credential is present.
    final credentialType = irmaConfig.credentialTypes[credentialTypeId]!;
    final attributeTypesLookup = _attributeTypesByCredentialType(irmaConfig)[credentialTypeId]!;

    final attributeValues = attributeTypesLookup.map((attributeType) {
      final value = attributeType.displayHint == 'portraitPhoto' ? portraitPhotoMock : _randomAttributeValue();
      return '"${attributeType.id}": "$value"';
    }).toList();

    return _issuanceSessionRequest([_credentialRequest(credentialType, attributeValues)]);
  }

  Future<String> randomIssuanceRequest(int amount) async {
    final credentialTypes = irmaConfig.credentialTypes.values.where((ct) => ct.schemeManagerId == 'irma-demo').toList();
    final attributeTypesLookup = _attributeTypesByCredentialType(irmaConfig);

    final credentialsJson = List<String>.generate(amount, (int i) {
      final credentialType = credentialTypes[_random.nextInt(credentialTypes.length)];
      final attributeValues = attributeTypesLookup[credentialType.fullId]!
          .map((attributeType) => '"${attributeType.id}": "${_randomAttributeValue()}"')
          .toList();

      return _credentialRequest(credentialType, attributeValues);
    });

    return _issuanceSessionRequest(credentialsJson);
  }
}
