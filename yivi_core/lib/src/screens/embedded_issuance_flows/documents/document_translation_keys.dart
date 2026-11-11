import "package:vcmrtd/vcmrtd.dart";

extension DocumentTranslationKeys on DocumentType {
  /// The document's prefix of its translation keys.
  String get keySegment => switch (this) {
    .passport => "passport",
    .identityCard => "id_card",
    .residencePermit => "residence_permit",
    .drivingLicence => "driving_licence",
  };

  /// App bar title shared with the MRZ scanning screen of this document.
  String get scanTitleKey => "$keySegment.scan.title";

  /// "Enter manually" on the MRZ scanning screen.
  String get scanManualKey => "$keySegment.scan.manual";

  /// A text of the manual entry screen: `{document}.manual.[part]`.
  String manualKey(String part) => "$keySegment.manual.$part";

  /// A text of the chip-reading screen: `{document}.nfc.[part]`.
  String nfcKey(String part) => "$keySegment.nfc.$part";

  /// App bar title of the chip-reading screen.
  String get nfcTitleKey => nfcKey("title");

  /// Where to find the details, under the manual entry fields.
  String get manualTipKey => "document_flow.manual.tip_$keySegment";

  /// The document's name, to fill the `{document}` placeholder of
  /// `document_flow.nfc.*` texts.
  String get nameKey => "document_flow.document.$keySegment";

  String get instructionKey => "document_flow.instruction.$keySegment";

  /// Names the NFC progress ring for screen readers.
  String get readingLabelKey => "document_flow.nfc.reading_label.$keySegment";
}
