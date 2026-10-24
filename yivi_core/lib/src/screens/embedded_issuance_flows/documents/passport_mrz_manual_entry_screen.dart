import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "widgets/date_input_field.dart";
import "widgets/document_nr_input_field.dart";
import "widgets/manual_entry_layout.dart";

class PassportMrzManualEntryTranslationKeys {
  final String title;
  final String explanation;
  final String dateOfBirth;
  final String dateOfBirthRequired;
  final String dateOfExpiry;
  final String dateOfExpiryRequired;
  final String documentNumber;
  final String documentNumberRequired;
  final String documentNumberInvalid;
  final String dateInvalid;

  /// The bar title: the scan title of the document ("Scan passport"), next
  /// to the heading in the page.
  String get appBarTitle => title.replaceFirst(".manual.title", ".scan.title");

  /// Where to find the details, under the fields.
  String get tip => title.startsWith("id_card")
      ? "document_flow.manual.tip_id_card"
      : "document_flow.manual.tip_passport";

  PassportMrzManualEntryTranslationKeys({
    required this.title,
    required this.explanation,
    required this.dateOfBirth,
    required this.dateOfBirthRequired,
    required this.dateOfExpiry,
    required this.dateOfExpiryRequired,
    required this.documentNumber,
    required this.documentNumberRequired,
    required this.documentNumberInvalid,
    required this.dateInvalid,
  });
}

/// Data returned on continue.
class PassportMrzManualEntryData {
  final String documentNr;
  final DateTime dateOfBirth;
  final DateTime expiryDate;

  PassportMrzManualEntryData({
    required this.documentNr,
    required this.dateOfBirth,
    required this.expiryDate,
  });
}

/// This screen is for when the camera doesn't work(?)
class PassportMrzManualEntryScreen extends StatefulWidget {
  /// Now receives the collected data from the 3 fields.
  final void Function(PassportMrzManualEntryData data) onContinue;
  final VoidCallback onCancel;
  final PassportMrzManualEntryTranslationKeys translationKeys;

  const PassportMrzManualEntryScreen({
    required this.onContinue,
    required this.onCancel,
    required this.translationKeys,
    super.key,
  });

  @override
  State<PassportMrzManualEntryScreen> createState() =>
      _PassportMrzManualEntryScreenState();
}

class _PassportMrzManualEntryScreenState
    extends State<PassportMrzManualEntryScreen> {
  final _manualEntryFormKey = GlobalKey<FormState>();

  final _documentNrCtrl = TextEditingController();
  final _dateOfBirthCtrl = TextEditingController();
  final _expiryDateCtrl = TextEditingController();

  bool _canContinue = false; // soft validity during typing

  void _recomputeCanContinue() {
    // Keep this light: avoid calling validate() here.
    final docOk = _documentNrCtrl.text.trim().isNotEmpty;
    final dobOk = _dateOfBirthCtrl.text.trim().isNotEmpty;
    final expOk = _expiryDateCtrl.text.trim().isNotEmpty;

    final can = docOk && dobOk && expOk;
    if (can != _canContinue) {
      setState(() => _canContinue = can);
    }
  }

  void _onContinuePressed() {
    final form = _manualEntryFormKey.currentState;
    if (form != null && form.validate()) {
      final data = PassportMrzManualEntryData(
        documentNr: _documentNrCtrl.text.trim(),
        dateOfBirth: _parseDate(_dateOfBirthCtrl.text.trim()),
        expiryDate: _parseDate(_expiryDateCtrl.text.trim()),
      );
      widget.onContinue(data);
    }
  }

  DateTime _parseDate(String input) {
    // The fields take yyyy-MM-dd (see DateInputField).
    final parts = input.split("-");
    if (parts.length != 3) {
      throw FormatException("Invalid date format: $input");
    }
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    return ManualEntryScaffold(
      appBarTitleKey: widget.translationKeys.appBarTitle,
      formKey: _manualEntryFormKey,
      onChanged: _recomputeCanContinue,
      titleKey: widget.translationKeys.title,
      explanationKey: widget.translationKeys.explanation,
      tipKey: widget.translationKeys.tip,
      onContinue: _canContinue ? _onContinuePressed : null,
      onCancel: widget.onCancel,
      fields: [
        DocumentNrInputField(
          controller: _documentNrCtrl,
          labelText: FlutterI18n.translate(
            context,
            widget.translationKeys.documentNumber,
          ),
          requiredText: FlutterI18n.translate(
            context,
            widget.translationKeys.documentNumberRequired,
          ),
          invalidText: FlutterI18n.translate(
            context,
            widget.translationKeys.documentNumberInvalid,
          ),
        ),
        DateInputField(
          controller: _dateOfBirthCtrl,
          fieldKey: const Key("passport_dob_field"),
          labelText: FlutterI18n.translate(
            context,
            widget.translationKeys.dateOfBirth,
          ),
          requiredText: FlutterI18n.translate(
            context,
            widget.translationKeys.dateOfBirthRequired,
          ),
          dateInvalidText: FlutterI18n.translate(
            context,
            widget.translationKeys.dateInvalid,
          ),
        ),
        DateInputField(
          controller: _expiryDateCtrl,
          fieldKey: const Key("passport_expiry_date_field"),
          dateInvalidText: FlutterI18n.translate(
            context,
            widget.translationKeys.dateInvalid,
          ),
          labelText: FlutterI18n.translate(
            context,
            widget.translationKeys.dateOfExpiry,
          ),
          requiredText: FlutterI18n.translate(
            context,
            widget.translationKeys.dateOfExpiryRequired,
          ),
        ),
      ],
    );
  }
}
