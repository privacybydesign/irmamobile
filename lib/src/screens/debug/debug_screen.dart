// This file is not null safe yet.
// @dart=2.11

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/credential_events.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/debug/portrait_photo_mock.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class DemoSessionHelper {
  static final _random = Random();

  static String disclosureSessionRequest() {
    return """
      {
        "@context": "https://irma.app/ld/request/disclosure/v2",
        "disclose": [
          [
            [
              "irma-demo.digidproef.personalData.fullname",
              "irma-demo.digidproef.personalData.initials",
              "irma-demo.digidproef.personalData.photo"
            ],
            [
              "irma-demo.gemeente.personalData.fullname",
              "irma-demo.gemeente.personalData.initials"
            ]
          ]
        ],
        "clientReturnUrl": "tel:+31612345678,1234567"
      }
    """;
  }

  static String signingSessionRequest() {
    return """
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
    """;
  }

  static String issuanceSessionRequest(List<String> credentialsJson) {
    return """
      {
        "@context": "https://irma.app/ld/request/issuance/v2",
        "credentials": [${credentialsJson.join(", ")}]
      }
    """;
  }

  static Map<String, List<AttributeType>> _attributeTypesByCredentialType(IrmaConfiguration irmaConfiguration) {
    return groupBy<AttributeType, String>(
      irmaConfiguration.attributeTypes.values,
      (attributeType) => attributeType.fullCredentialId,
    );
  }

  static String _credentialRequest(CredentialType credentialType, attributeValues) {
    return """
      {
        "credential": "${credentialType.fullId}",
        "attributes": {${attributeValues.join(", ")}}
      }
    """;
  }

  static String _randomAttributeValue() {
    const attributeValues = ["lorem", "ipsum"];
    return attributeValues[_random.nextInt(attributeValues.length)];
  }

  static Future<String> digidProefIssuanceRequest(Future<IrmaConfiguration> irmaConfigurationFuture) async {
    final irmaConfiguration = await irmaConfigurationFuture;
    const credentialTypeId = "irma-demo.digidproef.personalData";
    final credentialType = irmaConfiguration.credentialTypes[credentialTypeId];
    final attributeTypesLookup = _attributeTypesByCredentialType(irmaConfiguration)[credentialTypeId];

    final attributeValues = attributeTypesLookup.map((attributeType) {
      final value = attributeType.displayHint == "portraitPhoto" ? portraitPhotoMock : _randomAttributeValue();
      return '"${attributeType.id}": "$value"';
    }).toList();

    return issuanceSessionRequest(
      [_credentialRequest(credentialType, attributeValues)],
    );
  }

  static Future<String> randomIssuanceRequest(Future<IrmaConfiguration> irmaConfigurationFuture, int amount) async {
    final irmaConfiguration = await irmaConfigurationFuture;
    final credentialTypes =
        irmaConfiguration.credentialTypes.values.where((ct) => ct.schemeManagerId == "irma-demo").toList();
    final attributeTypesLookup = _attributeTypesByCredentialType(irmaConfiguration);

    final credentialsJson = List<String>.generate(amount, (int i) {
      final credentialType = credentialTypes[_random.nextInt(credentialTypes.length)];
      final attributeValues = attributeTypesLookup[credentialType.fullId]
          .map((attributeType) => '"${attributeType.id}": "${_randomAttributeValue()}"')
          .toList();

      return _credentialRequest(credentialType, attributeValues);
    });

    return issuanceSessionRequest(credentialsJson);
  }

  static Future<SessionPointer> startDebugSession(String requestBody) async {
    final Uri uri = Uri.parse("https://demo.privacybydesign.foundation/backend/session");

    final request = await HttpClient().postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.write(requestBody);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).first;

    if (response.statusCode != 200) {
      debugPrint("Status ${response.statusCode}: $responseBody");
      return null;
    }

    final responseObject = jsonDecode(responseBody) as Map<String, dynamic>;
    final sessionPtr = SessionPointer.fromJson(responseObject["sessionPtr"] as Map<String, dynamic>);
    // A debug session is not a regular mobile session, because there is no initiating app.
    // Therefore treat this session like it was started by scanning a QR.
    sessionPtr.continueOnSecondDevice = true;
    return sessionPtr;
  }
}

class DebugScreen extends StatelessWidget {
  static const routeName = "/debug";

  void _onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> _startDisclosureSession(BuildContext context) async {
    ScannerScreen.startSessionAndNavigate(
      Navigator.of(context),
      await DemoSessionHelper.startDebugSession(
        DemoSessionHelper.disclosureSessionRequest(),
      ),
    );
  }

  Future<void> _getCards(BuildContext context, Future<String> issuanceRequest) async {
    final sessionPointer = await DemoSessionHelper.startDebugSession(await issuanceRequest);
    ScannerScreen.startSessionAndNavigate(Navigator.of(context), sessionPointer);
  }

  Future<void> _deleteAllDeletableCards() async {
    final repo = IrmaRepository.get();
    final credentials = await repo.getCredentials().first;

    for (final credential in credentials.values) {
      if (credential.info.credentialType.disallowDelete) {
        continue;
      }

      repo.bridgedDispatch(DeleteCredentialEvent(hash: credential.hash));
    }
  }

  @override
  Widget build(BuildContext context) {
    final irmaConfigurationFuture = IrmaRepository.get().getIrmaConfiguration().first;

    return Scaffold(
      appBar: IrmaAppBar(
        title: const Text('Debugger'),
        leadingAction: () => _onClose(context),
        leadingIcon: Icon(Icons.arrow_back, semanticLabel: FlutterI18n.translate(context, "accessibility.back")),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.image),
            onPressed: () => _getCards(
              context,
              DemoSessionHelper.digidProefIssuanceRequest(irmaConfigurationFuture),
            ),
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _startDisclosureSession(context),
          ),
          IconButton(
            icon: Icon(Icons.exposure_plus_2),
            onPressed: () => _getCards(
              context,
              DemoSessionHelper.randomIssuanceRequest(irmaConfigurationFuture, 2),
            ),
          ),
          IconButton(
            icon: Icon(Icons.list_alt),
            onPressed: () => ScannerScreen.startIssueWizard(
                Navigator.of(context), SessionPointer(wizard: "irma-demo-requestors.ivido.demo-client")),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteAllDeletableCards(),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[Container()],
      ),
    );
  }
}
