import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";

Map<String, dynamic> _trustedPartyJson({List<String>? warnings}) => {
  "id": "verifier",
  "name": {"en": "Test verifier"},
  "url": null,
  "parent": null,
  "verified": true,
  "warnings": ?warnings,
};

void main() {
  group("TrustedParty.warnings", () {
    test("absent warnings field deserializes to an empty list", () {
      final party = TrustedParty.fromJson(_trustedPartyJson());
      expect(party.warnings, isEmpty);
    });

    test("known warning codes deserialize to their enum values", () {
      final party = TrustedParty.fromJson(
        _trustedPartyJson(
          warnings: ["did_web_dnssec_invalid", "did_web_dnssec_missing"],
        ),
      );
      expect(party.warnings, [
        SessionWarning.didWebDnssecInvalid,
        SessionWarning.didWebDnssecMissing,
      ]);
    });

    test("an unrecognized warning code maps to unknown, not an exception", () {
      final party = TrustedParty.fromJson(
        _trustedPartyJson(
          warnings: ["did_web_dnssec_invalid", "some_future_warning"],
        ),
      );
      expect(party.warnings, [
        SessionWarning.didWebDnssecInvalid,
        SessionWarning.unknown,
      ]);
    });
  });
}
