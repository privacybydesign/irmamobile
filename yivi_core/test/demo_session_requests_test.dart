import "dart:convert";
import "dart:math";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/demo_session_requests.dart";
import "package:yivi_core/src/models/irma_configuration.dart";

const _fullName = "irma-demo.MijnOverheid.fullName";
const _studentCard = "irma-demo.RU.studentCard";
const _mobile = "irma-demo.sidn-pbdf.mobilenumber";
const _member = "irma-demo.IRMATube.member";

DemoSessionRequests _requests() => DemoSessionRequests({
  _fullName: ["firstname", "familyname"],
  _studentCard: ["university", "studentCardNumber"],
  _mobile: ["mobilenumber"],
  _member: ["type", "id"],
  "irma-demo.other.credential": ["value"],
}, random: Random(1));

void main() {
  test("knows the test flow credentials of the configuration, in order", () {
    expect(_requests().known, [_fullName, _studentCard, _mobile, _member]);
    expect(DemoSessionRequests({_mobile: []}).known, isEmpty);
  });

  test("picks missing credentials from the ones not held", () {
    final requests = _requests();

    expect(requests.missing({_fullName}, 2), [_studentCard, _mobile]);
    expect(
      requests.missing({_fullName, _studentCard, _mobile, _member}, 1),
      isEmpty,
    );
    expect(requests.heldOf({_member, _fullName, "pbdf.pbdf.email"}), [
      _fullName,
      _member,
    ]);
  });

  test("a disclosure asks for each credential on its own", () {
    final request = jsonDecode(_requests().disclosure([_fullName, _mobile]));

    expect(request["@context"], "https://irma.app/ld/request/disclosure/v2");
    expect(request["disclose"], [
      [
        ["$_fullName.firstname"],
      ],
      [
        ["$_mobile.mobilenumber"],
      ],
    ]);
  });

  test("a choice asks for one of the credentials", () {
    final request = jsonDecode(_requests().choice([_fullName, _studentCard]));

    expect(request["disclose"], [
      [
        ["$_fullName.firstname"],
        ["$_studentCard.university"],
      ],
    ]);
  });

  test("an issuance fills every attribute with a made-up value", () {
    final request = jsonDecode(_requests().issuance([_fullName, _member]));

    expect(request["@context"], "https://irma.app/ld/request/issuance/v2");
    final credentials = request["credentials"] as List;
    expect(credentials.map((c) => c["credential"]), [_fullName, _member]);
    for (final credential in credentials) {
      final attributes = credential["attributes"] as Map;
      expect(attributes.values, everyElement(isNotEmpty));
    }
    expect((credentials.first["attributes"] as Map).keys, [
      "firstname",
      "familyname",
    ]);
  });

  test("reads the attributes from the configuration in their order", () {
    AttributeType attribute(String id, int index) => AttributeType(
      id: id,
      index: index,
      credentialTypeId: "member",
      issuerId: "IRMATube",
      schemeManagerId: "irma-demo",
    );
    final configuration = IrmaConfiguration(
      schemeManagers: {},
      requestorSchemes: {},
      requestors: {},
      issuers: {},
      credentialTypes: {},
      attributeTypes: {
        "$_member.id": attribute("id", 1),
        "$_member.type": attribute("type", 0),
      },
      issueWizards: {},
      path: "",
    );

    final requests = DemoSessionRequests.fromConfiguration(configuration);

    expect(requests.attributesByCredential[_member], ["type", "id"]);
    expect(requests.known, [_member]);
  });
}
