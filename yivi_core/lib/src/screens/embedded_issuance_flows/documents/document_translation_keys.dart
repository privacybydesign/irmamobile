import "package:vcmrtd/vcmrtd.dart";

extension DocumentTranslationKeys on DocumentType {
  String get _segment => switch (this) {
    .passport => "passport",
    .identityCard => "id_card",
    .drivingLicence => "driving_licence",
  };

  /// App bar title shared with the MRZ scanning screen of this document.
  String get scanTitleKey => "$_segment.scan.title";

  /// The document's name, to fill the `{document}` placeholder of
  /// `document_flow.nfc.*` texts.
  String get nameKey => "document_flow.document.$_segment";

  String get instructionKey => "document_flow.instruction.$_segment";
}
