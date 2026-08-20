import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/util/nfc_credentials.dart";

void main() {
  group("credentialRequiresNfc", () {
    test("true for document credentials that need onboard NFC scanning", () {
      expect(credentialRequiresNfc("pbdf.pbdf.passport"), isTrue);
      expect(credentialRequiresNfc("pbdf.pbdf.drivinglicence"), isTrue);
      expect(credentialRequiresNfc("pbdf.pbdf.idcard"), isTrue);
      expect(credentialRequiresNfc("pbdf-staging.pbdf.passport"), isTrue);
      expect(credentialRequiresNfc("pbdf-staging.pbdf.drivinglicence"), isTrue);
      expect(credentialRequiresNfc("pbdf-staging.pbdf.idcard"), isTrue);
    });

    test("false for credentials that don't need NFC", () {
      expect(credentialRequiresNfc("pbdf.sidn-pbdf.email"), isFalse);
      expect(credentialRequiresNfc("pbdf.sidn-pbdf.mobilenumber"), isFalse);
      expect(credentialRequiresNfc("pbdf.gemeente.personalData"), isFalse);
    });
  });
}
