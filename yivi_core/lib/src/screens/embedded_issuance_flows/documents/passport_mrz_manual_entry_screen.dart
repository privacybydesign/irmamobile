import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "document_translation_keys.dart";
import "widgets/date_input_field.dart";
import "widgets/document_nr_input_field.dart";
import "widgets/manual_entry_layout.dart";

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

/// Typing the MRZ in by hand, for when the camera cannot read it ("Enter
/// manually" on the camera screen).
class PassportMrzManualEntryScreen extends StatefulWidget {
  /// Receives what was typed in the three fields.
  final void Function(PassportMrzManualEntryData data) onContinue;
  final VoidCallback onCancel;

  /// A passport or a card in ID-card format: whose texts it shows.
  final DocumentType documentType;

  const PassportMrzManualEntryScreen({
    required this.onContinue,
    required this.onCancel,
    required this.documentType,
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

  @override
  void dispose() {
    _documentNrCtrl.dispose();
    _dateOfBirthCtrl.dispose();
    _expiryDateCtrl.dispose();
    super.dispose();
  }

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
    final type = widget.documentType;
    String t(String field) =>
        FlutterI18n.translate(context, type.manualKey("fields.$field"));
    return ManualEntryScaffold(
      appBarTitleKey: type.scanTitleKey,
      formKey: _manualEntryFormKey,
      onChanged: _recomputeCanContinue,
      titleKey: type.manualKey("title"),
      explanationKey: type.manualKey("explanation"),
      tipKey: type.manualTipKey,
      onContinue: _canContinue ? _onContinuePressed : null,
      onCancel: widget.onCancel,
      fields: [
        DocumentNrInputField(
          controller: _documentNrCtrl,
          labelText: t("document_nr"),
          requiredText: t("document_nr_required"),
          invalidText: t("document_nr_invalid"),
        ),
        DateInputField(
          controller: _dateOfBirthCtrl,
          fieldKey: const Key("passport_dob_field"),
          labelText: t("date_of_birth"),
          requiredText: t("date_of_birth_required"),
          dateInvalidText: t("date_invalid"),
        ),
        DateInputField(
          controller: _expiryDateCtrl,
          fieldKey: const Key("passport_expiry_date_field"),
          dateInvalidText: t("date_invalid"),
          labelText: t("date_of_expiry"),
          requiredText: t("date_of_expiry_required"),
        ),
      ],
    );
  }
}
