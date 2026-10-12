import "dart:convert";
import "dart:math";

import "package:collection/collection.dart";

import "../models/irma_configuration.dart";

/// The demo IRMA server the test flows run on (see `createTestSession`).
const demoServerHost = "is.demo.staging.yivi.app";

/// The demo scheme's BSN, which counts as sensitive.
const demoBsnAttributeId = "irma-demo.gemeente.personalData.bsn";

/// The demo credentials the test flows in the debug menu use. Their sessions
/// run on the demo IRMA server (see `createTestSession`), which knows the
/// official irma-demo scheme, so these all come from there and all have an
/// issue URL, which makes them obtainable during a disclosure.
const demoCredentialIds = [
  "irma-demo.MijnOverheid.fullName",
  "irma-demo.RU.studentCard",
  "irma-demo.sidn-pbdf.mobilenumber",
  "irma-demo.IRMATube.member",
  "irma-demo.MijnOverheid.address",
];

/// Session requests for the test flows in the debug menu, and for getting a
/// demo credential in the app instead of on its website.
class DemoSessionRequests {
  /// The attribute ids of each credential type, in their order.
  final Map<String, List<String>> attributesByCredential;
  final Random _random;

  DemoSessionRequests(this.attributesByCredential, {Random? random})
    : _random = random ?? Random();

  factory DemoSessionRequests.fromConfiguration(IrmaConfiguration config) {
    final byCredential = groupBy<AttributeType, String>(
      config.attributeTypes.values,
      (attribute) => attribute.fullCredentialId,
    );
    return DemoSessionRequests({
      for (final MapEntry(:key, :value) in byCredential.entries)
        key: (value.toList()..sortBy<num>((a) => a.index))
            .map((a) => a.id)
            .toList(),
    });
  }

  /// The test flow credentials this configuration knows.
  List<String> get known => demoCredentialIds
      .where((id) => attributesByCredential[id]?.isNotEmpty ?? false)
      .toList();

  /// Up to [count] test flow credentials that are not in [held].
  List<String> missing(Set<String> held, int count) =>
      known.where((id) => !held.contains(id)).take(count).toList();

  /// The test flow credentials in [held].
  List<String> heldOf(Set<String> held) =>
      known.where((id) => held.contains(id)).toList();

  /// Asks for the first attribute of each of [credentialIds], each on its own.
  String disclosure(List<String> credentialIds) => jsonEncode({
    "@context": "https://irma.app/ld/request/disclosure/v2",
    "disclose": [
      for (final id in credentialIds)
        [
          [_firstAttribute(id)],
        ],
    ],
  });

  /// Asks for each of [attributeIds] (`<credential id>.<attribute id>`).
  String disclosureOfAttributes(List<String> attributeIds) => jsonEncode({
    "@context": "https://irma.app/ld/request/disclosure/v2",
    "disclose": [
      for (final id in attributeIds)
        [
          [id],
        ],
    ],
  });

  /// Asks for the first attribute of one of [credentialIds].
  String choice(List<String> credentialIds) => jsonEncode({
    "@context": "https://irma.app/ld/request/disclosure/v2",
    "disclose": [
      [
        for (final id in credentialIds) [_firstAttribute(id)],
      ],
    ],
  });

  /// Issues [credentialIds], every attribute with a made-up value.
  String issuance(List<String> credentialIds) => jsonEncode({
    "@context": "https://irma.app/ld/request/issuance/v2",
    "credentials": [
      for (final id in credentialIds)
        {
          "credential": id,
          "attributes": {
            for (final attribute in attributesByCredential[id]!)
              attribute: _madeUpValue(),
          },
        },
    ],
  });

  String _firstAttribute(String credentialId) =>
      "$credentialId.${attributesByCredential[credentialId]!.first}";

  String _madeUpValue() {
    const values = ["lorem", "ipsum", "dolor"];
    return values[_random.nextInt(values.length)];
  }
}
