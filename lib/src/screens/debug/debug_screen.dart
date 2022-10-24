import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../models/credential_events.dart';
import '../../models/irma_configuration.dart';
import '../../models/session.dart';
import '../../util/handle_pointer.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import 'manage_schemes_screen.dart';
import 'portrait_photo_mock.dart';
import 'session_helper_screen.dart';

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

class DebugScreen extends StatelessWidget {
  static const routeName = '/debug';

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

  Widget _buildTile({
    required IconData icon,
    required String title,
    required GestureTapCallback onTap,
  }) =>
      ListTile(
        leading: Icon(icon),
        title: Text(title),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);
    final irmaConfigurationFuture = repo.getIrmaConfiguration().first;

    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'Debugger',
        leadingAction: () => _onClose(context),
      ),
      body: ListView(
        children: [
          _buildTile(
            icon: Icons.image,
            title: 'Add credential with image',
            onTap: () => _getCards(
              context,
              DemoSessionHelper.digidProefIssuanceRequest(irmaConfigurationFuture),
            ),
          ),
          _buildTile(
            icon: Icons.exposure_plus_2,
            title: 'Add two credentials',
            onTap: () => _getCards(
              context,
              DemoSessionHelper.randomIssuanceRequest(irmaConfigurationFuture, 2),
            ),
          ),
          _buildTile(
            icon: Icons.list_alt,
            title: 'Do a custom issue wizard',
            onTap: () => handlePointer(
              Navigator.of(context),
              IssueWizardPointer('irma-demo-requestors.ivido.demo-client'),
            ),
          ),
          _buildTile(
            icon: Icons.share,
            title: 'Do a disclosure session',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => SessionHelperScreen(
                initialRequest: DemoSessionHelper.disclosureSessionRequest(),
              ),
            )),
          ),
          _buildTile(
            icon: Icons.edit,
            title: 'Do a signature session',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => SessionHelperScreen(
                initialRequest: DemoSessionHelper.signingSessionRequest(),
              ),
            )),
          ),
          _buildTile(
            icon: Icons.manage_accounts,
            title: 'Manage schemes',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ManageSchemesScreen(irmaRepository: repo),
            )),
          ),
          _buildTile(
            icon: Icons.delete,
            title: 'Delete all credentials',
            onTap: () => _deleteAllDeletableCards(context),
          ),
        ],
      ),
    );
  }
}
