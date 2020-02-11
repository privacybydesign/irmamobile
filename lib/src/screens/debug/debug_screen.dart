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
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class DemoSessionHelper {
  static String disclosureSessionRequest() {
    return """
      {
        "@context": "https://irma.app/ld/request/disclosure/v2",
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

  static String randomIssuanceRequest(IrmaConfiguration irmaConfiguration, int amount) {
    final credentialTypes =
        irmaConfiguration.credentialTypes.values.where((ct) => ct.schemeManagerId == "irma-demo").toList();
    final attributesByCredentialType = groupBy<AttributeType, String>(
      irmaConfiguration.attributeTypes.values,
      (attributeType) => attributeType.fullCredentialId,
    );

    final random = Random();
    const attributeValues = ["lorem", "ipsum"];
    String randomAttributeValue() => attributeValues[random.nextInt(attributeValues.length)];

    final credentialsJson = List<String>.generate(amount, (int i) {
      final credentialType = credentialTypes[random.nextInt(credentialTypes.length)];
      final attributeValues = attributesByCredentialType[credentialType.fullId]
          .map((attributeType) => '"${attributeType.id}": "${randomAttributeValue()}"')
          .toList();

      return """
         {
           "credential": "${credentialType.fullId}",
           "validity": 1592438400,
           "attributes": {${attributeValues.join(", ")}}
         }
       """;
    });

    return issuanceSessionRequest(credentialsJson);
  }

  static Future<SessionPointer> startDebugSession(String requestBody) async {
    final Uri uri = Uri.parse("https://metrics.privacybydesign.foundation/irmaserver/session");

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
    return SessionPointer.fromJson(responseObject["sessionPtr"] as Map<String, dynamic>);
  }
}

class DebugScreen extends StatelessWidget {
  static const routeName = "/debug";

  void _onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> _startDisclosureSession(BuildContext context) async {
    ScannerScreen.startSessionAndNavigate(
      context,
      await DemoSessionHelper.startDebugSession(
        DemoSessionHelper.disclosureSessionRequest(),
      ),
    );
  }

  Future<void> _getRandomCards(BuildContext context) async {
    final irmaConfiguration = await IrmaRepository.get().getIrmaConfiguration().first;
    final sessionPointer = await DemoSessionHelper.startDebugSession(
      DemoSessionHelper.randomIssuanceRequest(irmaConfiguration, 2),
    );

    ScannerScreen.startSessionAndNavigate(context, sessionPointer);
  }

  Future<void> _deleteAllDeletableCards() async {
    final repo = IrmaRepository.get();
    final credentials = await repo.getCredentials().first;

    for (final credential in credentials.values) {
      if (credential.credentialType.disallowDelete) {
        continue;
      }

      repo.bridgedDispatch(DeleteCredentialEvent(hash: credential.hash));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: const Text('Debugger'),
        leadingAction: () => _onClose(context),
        leadingIcon: Icon(Icons.arrow_back, semanticLabel: FlutterI18n.translate(context, "accessibility.back")),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.share), onPressed: () => _startDisclosureSession(context)),
          IconButton(icon: Icon(Icons.exposure_plus_2), onPressed: () => _getRandomCards(context)),
          IconButton(icon: Icon(Icons.delete), onPressed: () => _deleteAllDeletableCards()),
        ],
      ),
      body: Stack(
        children: <Widget>[Container()],
      ),
    );
  }
}
