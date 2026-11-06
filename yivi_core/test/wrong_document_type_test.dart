import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:vcmrtd/vcmrtd.dart";

import "package:yivi_core/src/screens/embedded_issuance_flows/documents/nfc_reading_screen.dart";

/// A card in ID-card format issued by Utopia (UTO) to a holder of
/// [nationality].
PassportData _td1Card({required String code, required String nationality}) {
  final mrz =
      "${code}UTOD231458907<<<<<<<<<<<<<<<"
      "7408122F1204159$nationality<<<<<<<<<<<6"
      "ERIKSSON<<ANNA<MARIA<<<<<<<<<<";
  return PassportData(
    mrz: PassportMRZ(Uint8List.fromList(mrz.codeUnits)),
    photoImageData: Uint8List(0),
    photoImageType: .jpeg,
    photoImageWidth: 0,
    photoImageHeight: 0,
  );
}

void main() {
  group("wrongDocumentType", () {
    test("a residence permit read as an ID card is the wrong document", () {
      final permit = _td1Card(code: "IR", nationality: "SYR");
      expect(
        wrongDocumentType(permit, .identityCard),
        DocumentType.residencePermit,
      );
      expect(wrongDocumentType(permit, .residencePermit), isNull);
    });

    test("an ID card read as a residence permit is the wrong document", () {
      final card = _td1Card(code: "I<", nationality: "UTO");
      expect(
        wrongDocumentType(card, .residencePermit),
        DocumentType.identityCard,
      );
      expect(wrongDocumentType(card, .identityCard), isNull);
    });

    // The passport issuer issues an ID card only to a national of the issuing
    // state, so a foreigner's card with an ID-card code is never an ID card.
    test("a foreigner's card with an ID-card code is not an ID card", () {
      final card = _td1Card(code: "ID", nationality: "MAR");
      expect(
        wrongDocumentType(card, .identityCard),
        DocumentType.residencePermit,
      );
      expect(wrongDocumentType(card, .residencePermit), isNull);
    });

    test("passports and driving licences are not checked", () {
      final permit = _td1Card(code: "IR", nationality: "SYR");
      expect(wrongDocumentType(permit, .passport), isNull);
      expect(wrongDocumentType(permit, .drivingLicence), isNull);
    });
  });
}
