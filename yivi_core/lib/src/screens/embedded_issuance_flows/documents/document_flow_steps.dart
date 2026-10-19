import "package:material_ui/material_ui.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../models/mrz.dart";
import "document_instruction_screen.dart";
import "driving_licence_mrz_manual_entry_screen.dart";
import "mrz_reader_screen.dart";
import "nfc_reading_screen.dart";
import "passport_mrz_manual_entry_screen.dart";

/// The steps of adding a document (passport, ID card, driving licence), each
/// with its callbacks: the full-screen routes and the Change sheet show the
/// same screens and only differ in where the next step goes. In a sheet they
/// show without their own bar (see `DocumentStepInSheet`).
abstract final class DocumentFlowSteps {
  static String _segment(DocumentType type) => switch (type) {
    .passport => "passport",
    .identityCard => "id_card",
    .drivingLicence => "driving_licence",
  };

  /// How to hold the document; [onStart] goes on to the camera or the
  /// manual entry.
  static Widget instruction(
    DocumentType type, {
    required VoidCallback onStart,
    required VoidCallback onCancel,
  }) => DocumentInstructionScreen(
    documentType: type,
    onStart: onStart,
    onCancel: onCancel,
  );

  /// The camera reading the MRZ; [onRead] gets what it read.
  static Widget reader(
    DocumentType type, {
    required ValueChanged<ScannedMrz> onRead,
    required VoidCallback onManual,
    required VoidCallback onCancel,
  }) {
    final s = _segment(type);
    final keys = MrzReaderTranslationKeys(
      title: "$s.scan.title",
      manualEntryButton: "$s.scan.manual",
      error: "$s.scan.error",
      success: "$s.scan.success",
      successExplanation: "$s.scan.success_explanation",
    );
    return switch (type) {
      .drivingLicence => MrzReaderScreen(
        translationKeys: keys,
        onSuccess: (r) => onRead(
          ScannedDrivingLicenceMrz.fromMRZResult(r as DrivingLicenceMrzResult),
        ),
        onManualAdd: onManual,
        onCancel: onCancel,
        mrzParser: DrivingLicenceMrzParser(),
      ),
      .passport => MrzReaderScreen(
        translationKeys: keys,
        onSuccess: (r) =>
            onRead(ScannedPassportMrz.fromMRZResult(r as PassportMrzResult)),
        onManualAdd: onManual,
        onCancel: onCancel,
        mrzParser: PassportMrzParser(),
      ),
      .identityCard => MrzReaderScreen(
        translationKeys: keys,
        onSuccess: (r) =>
            onRead(ScannedIdCardMrz.fromMRZResult(r as PassportMrzResult)),
        onManualAdd: onManual,
        onCancel: onCancel,
        mrzParser: IdCardMrzParser(),
      ),
    };
  }

  /// Typing the MRZ details in; [onRead] gets them.
  static Widget manualEntry(
    DocumentType type, {
    required ValueChanged<ScannedMrz> onRead,
    required VoidCallback onCancel,
  }) {
    if (type == .drivingLicence) {
      return DrivingLicenceMrzManualEntryScreen(
        onCancel: onCancel,
        onContinue: (data) => onRead(
          ScannedDrivingLicenceMrz(
            documentNumber: data.documentNumber,
            countryCode: data.countryCode,
            version: data.version,
            randomData: data.randomData,
            configuration: data.configuration,
          ),
        ),
      );
    }
    final s = _segment(type);
    return PassportMrzManualEntryScreen(
      translationKeys: PassportMrzManualEntryTranslationKeys(
        title: "$s.manual.title",
        explanation: "$s.manual.explanation",
        dateOfBirth: "$s.manual.fields.date_of_birth",
        dateOfBirthRequired: "$s.manual.fields.date_of_birth_required",
        dateOfExpiry: "$s.manual.fields.date_of_expiry",
        dateOfExpiryRequired: "$s.manual.fields.date_of_expiry_required",
        documentNumber: "$s.manual.fields.document_nr",
        documentNumberRequired: "$s.manual.fields.document_nr_required",
        documentNumberInvalid: "$s.manual.fields.document_nr_invalid",
        dateInvalid: "$s.manual.fields.date_invalid",
      ),
      onCancel: onCancel,
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
              ),
      ),
    );
  }

  /// Reading the chip, then starting the issuance (`handlePointer`).
  static Widget nfc(
    ScannedMrz mrz, {
    required VoidCallback onCancel,
    Future<bool> Function(BuildContext context)? faceIntro,
  }) {
    final s = _segment(mrz.documentType);
    return NfcReadingScreen(
      translationKeys: NfcReadingTranslationKeys(
        cancelDialogTitle: "$s.nfc.cancel_dialog.title",
        cancelDialogExplanation: "$s.nfc.cancel_dialog.explanation",
        cancelDialogDecline: "$s.nfc.cancel_dialog.decline",
        cancelDialogConfirm: "$s.nfc.cancel_dialog.confirm",
        error: "$s.nfc.error",
        errorGeneric: "$s.nfc.error_generic",
        title: "$s.nfc.title",
        holdNearPhotoPage: "$s.nfc.hold_near_photo_page",
        tip1: "$s.nfc.tip_1",
        tip2: "$s.nfc.tip_2",
        tip3: "$s.nfc.tip_3",
        successExplanation: "$s.nfc.success_explanation",
        cancelledByUser: "$s.nfc.cancelled_by_user",
        cancelled: "$s.nfc.cancelled",
        cancelling: "$s.nfc.cancelling",
        connecting: "$s.nfc.connecting",
        readingCardSecurity: "$s.nfc.reading_card_security",
        readingDocumentData: "$s.nfc.reading_passport_data",
        authenticating: "$s.nfc.authenticating",
        performingSecurityVerification:
            "$s.nfc.performing_security_verification",
        timeoutWaitingForTag: "$s.nfc.timeout_waiting_for_tag",
        tagLostTryAgain: "$s.nfc.tag_lost_try_again",
        failedToInitiateSession: "$s.nfc.failed_to_initiate_session",
        success: "$s.nfc.success",
      ),
      mrz: mrz,
      onCancel: onCancel,
    );
  }
}
