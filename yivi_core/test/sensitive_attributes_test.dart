import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/sensitive_attributes.dart";
import "package:yivi_core/src/models/schemaless/session_user_interaction.dart";

SelectedCredential _credential(String id, List<List<dynamic>> paths) =>
    SelectedCredential(
      credentialId: id,
      credentialHash: "hash",
      attributePaths: paths,
    );

void main() {
  group("sharesSensitiveAttribute", () {
    test("is true when the BSN is disclosed", () {
      final credentials = [
        _credential("pbdf.gemeente.personalData", [
          ["fullname"],
          ["bsn"],
        ]),
      ];

      expect(sharesSensitiveAttribute(credentials), isTrue);
    });

    test("is true when the BSN is in the second credential", () {
      final credentials = [
        _credential("pbdf.sidn-pbdf.email", [
          ["email"],
        ]),
        _credential("pbdf.gemeente.personalData", [
          ["bsn"],
        ]),
      ];

      expect(sharesSensitiveAttribute(credentials), isTrue);
    });

    test("is false when only other attributes are disclosed", () {
      final credentials = [
        _credential("pbdf.gemeente.personalData", [
          ["fullname"],
          ["dateofbirth"],
        ]),
      ];

      expect(sharesSensitiveAttribute(credentials), isFalse);
    });

    test("is false for an attribute id that only ends the same way", () {
      final credentials = [
        _credential("irma-demo.gemeente.personalData", [
          ["bsn"],
        ]),
      ];

      expect(sharesSensitiveAttribute(credentials), isFalse);
    });

    test("is false when nothing is disclosed", () {
      expect(sharesSensitiveAttribute([]), isFalse);
    });
  });
}
