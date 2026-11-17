import "package:material_ui/material_ui.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../models/mrz.dart";
import "document_flow.dart";
import "document_instruction_screen.dart";
import "driving_licence_mrz_manual_entry_screen.dart";
import "mrz_reader_screen.dart";
import "nfc_reading_screen.dart";
import "passport_mrz_manual_entry_screen.dart";

/// The steps of adding a document (passport, ID card, driving licence), each
/// with its callbacks, as the sheet shows them (see `DocumentSheetStep`):
/// without a bar of their own.
abstract final class DocumentFlowSteps {
  /// How to hold the document; [onStart] goes on to the camera or the
  /// manual entry.
  static Widget instruction(
    DocumentType type, {
    required VoidCallback onStart,
  }) => DocumentInstructionScreen(documentType: type, onStart: onStart);

  /// The camera reading the MRZ; [onRead] gets what it read.
  static Widget reader(
    DocumentType type, {
    required ValueChanged<ScannedMrz> onRead,
    required VoidCallback onManual,
  }) {
    final (
      MrzParser parser,
      ScannedMrz Function(MrzResult) scanned,
    ) = switch (type) {
      .drivingLicence => (
        DrivingLicenceMrzParser(),
        (r) => ScannedDrivingLicenceMrz.fromMRZResult(
          r as DrivingLicenceMrzResult,
        ),
      ),
      .passport => (
        PassportMrzParser(),
        (r) => ScannedPassportMrz.fromMRZResult(r as PassportMrzResult),
      ),
      // A residence permit is a card in ID-card format too.
      .identityCard || .residencePermit => (
        IdCardMrzParser(),
        (r) => ScannedIdCardMrz.fromMRZResult(
          r as PassportMrzResult,
          documentType: type,
        ),
      ),
    };
    return MrzReaderScreen(
      documentType: type,
      onSuccess: (r) => onRead(scanned(r)),
      onManualAdd: onManual,
      mrzParser: parser,
    );
  }

  /// Typing the MRZ details in; [onRead] gets them.
  static Widget manualEntry(
    DocumentType type, {
    required ValueChanged<ScannedMrz> onRead,
  }) {
    if (type == .drivingLicence) {
      return DrivingLicenceMrzManualEntryScreen(
        onContinue: (r) => onRead(ScannedDrivingLicenceMrz.fromMRZResult(r)),
      );
    }
    return PassportMrzManualEntryScreen(
      documentType: type,
      onContinue: (data) => onRead(
        type == .passport
            ? ScannedPassportMrz.fromManualEntry(
                documentNumber: data.documentNr,
                dateOfBirth: data.dateOfBirth,
                dateOfExpiry: data.expiryDate,
              )
            : ScannedIdCardMrz.fromManualEntry(
                documentNumber: data.documentNr,
                dateOfBirth: data.dateOfBirth,
                dateOfExpiry: data.expiryDate,
                documentType: type,
              ),
      ),
    );
  }

  /// Reading the chip, then adding it (`DocumentIssuance`).
  static Widget nfc(ChipRead read) =>
      NfcReadingScreen(mrz: read.mrz, attempt: read.attempt);
}
