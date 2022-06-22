import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/credential_events.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/screens/debug/portrait_photo_mock.dart';
import 'package:irmamobile/src/util/handle_pointer.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_repository_provider.dart';

// ignore: avoid_classes_with_only_static_members
class DemoSessionHelper {
  static final _random = Random();

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

  static String issuanceSessionRequest(List<String> credentialsJson) {
    return '''
      {
        "@context": "https://irma.app/ld/request/issuance/v2",
        "credentials": [${credentialsJson.join(", ")}]
      }
    ''';
  }

  static Map<String, List<AttributeType>> _attributeTypesByCredentialType(IrmaConfiguration irmaConfiguration) {
    return groupBy<AttributeType, String>(
      irmaConfiguration.attributeTypes.values,
      (attributeType) => attributeType.fullCredentialId,
    );
  }

  static String _credentialRequest(CredentialType credentialType, attributeValues) {
    return '''
      {
        "credential": "${credentialType.fullId}",
        "attributes": {${attributeValues.join(", ")}}
      }
    ''';
  }

  static String _randomAttributeValue() {
    const attributeValues = ['lorem', 'ipsum'];
    return attributeValues[_random.nextInt(attributeValues.length)];
  }

  static Future<String> digidProefIssuanceRequest(Future<IrmaConfiguration> irmaConfigurationFuture) async {
    final irmaConfiguration = await irmaConfigurationFuture;
    const credentialTypeId = 'irma-demo.digidproef.personalData'; // We assume this credential is present.
    final credentialType = irmaConfiguration.credentialTypes[credentialTypeId]!;
    final attributeTypesLookup = _attributeTypesByCredentialType(irmaConfiguration)[credentialTypeId]!;

    final attributeValues = attributeTypesLookup.map((attributeType) {
      final value = attributeType.displayHint == 'portraitPhoto' ? portraitPhotoMock : _randomAttributeValue();
      return '"${attributeType.id}": "$value"';
    }).toList();

    return issuanceSessionRequest(
      [_credentialRequest(credentialType, attributeValues)],
    );
  }

  static Future<String> randomIssuanceRequest(Future<IrmaConfiguration> irmaConfigurationFuture, int amount) async {
    final irmaConfiguration = await irmaConfigurationFuture;
    final credentialTypes =
        irmaConfiguration.credentialTypes.values.where((ct) => ct.schemeManagerId == 'irma-demo').toList();
    final attributeTypesLookup = _attributeTypesByCredentialType(irmaConfiguration);

    final credentialsJson = List<String>.generate(amount, (int i) {
      final credentialType = credentialTypes[_random.nextInt(credentialTypes.length)];
      final attributeValues = attributeTypesLookup[credentialType.fullId]!
          .map((attributeType) => '"${attributeType.id}": "${_randomAttributeValue()}"')
          .toList();

      return _credentialRequest(credentialType, attributeValues);
    });

    return issuanceSessionRequest(credentialsJson);
  }
}

class DebugScreen extends StatefulWidget {
  static const routeName = '/debug';

  @override
  State<StatefulWidget> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _controller = TextEditingController(text: DemoSessionHelper.disclosureSessionRequest());

  void _onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> _getCards(BuildContext context, Future<String> issuanceRequest) async =>
      IrmaRepositoryProvider.of(context).startTestSession(await issuanceRequest);

  Future<void> _deleteAllDeletableCards(BuildContext context) async {
    final repo = IrmaRepositoryProvider.of(context);
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
    final irmaConfigurationFuture = IrmaRepositoryProvider.of(context).getIrmaConfiguration().first;

    return Scaffold(
      appBar: IrmaAppBar(
        title: const Text('Debugger'),
        leadingAction: () => _onClose(context),
        leadingIcon: Icon(Icons.arrow_back, semanticLabel: FlutterI18n.translate(context, 'accessibility.back')),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: () => _getCards(
              context,
              DemoSessionHelper.digidProefIssuanceRequest(irmaConfigurationFuture),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exposure_plus_2),
            onPressed: () => _getCards(
              context,
              DemoSessionHelper.randomIssuanceRequest(irmaConfigurationFuture, 2),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => handlePointer(
              Navigator.of(context),
              IssueWizardPointer('irma-demo-requestors.ivido.demo-client'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteAllDeletableCards(context),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => IrmaRepositoryProvider.of(context).startTestSession(_controller.text),
          ),
        ],
      ),
      body: TextField(
        controller: _controller,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        expands: true,
      ),
    );
  }
}
