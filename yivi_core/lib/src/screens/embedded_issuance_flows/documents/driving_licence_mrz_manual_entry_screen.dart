import "package:material_ui/material_ui.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:vcmrtd/vcmrtd.dart";

import "document_translation_keys.dart";
import "widgets/driving_licence_mrz_field.dart";
import "widgets/manual_entry_layout.dart";

/// Typing the MRZ in by hand, for when the camera cannot read it ("Enter
/// manually" on the camera screen).
class DrivingLicenceMrzManualEntryScreen extends StatefulWidget {
  /// Receives the parsed MRZ.
  final void Function(DrivingLicenceMrzResult result) onContinue;
  final VoidCallback onCancel;

  const DrivingLicenceMrzManualEntryScreen({
    required this.onContinue,
    required this.onCancel,
    super.key,
  });

  @override
  State<DrivingLicenceMrzManualEntryScreen> createState() =>
      _DrivingLicenceMrzManualEntryScreenState();
}

class _DrivingLicenceMrzManualEntryScreenState
    extends State<DrivingLicenceMrzManualEntryScreen> {
  final _manualEntryFormKey = GlobalKey<FormState>();
  final _documentNrCtrl = TextEditingController();

  DrivingLicenceMrzResult? _parsed; // soft validity during typing

  bool get _canContinue => _parsed != null;

  @override
  void dispose() {
    _documentNrCtrl.dispose();
    super.dispose();
  }

  void _recomputeCanContinue() {
    final could = _canContinue;
    _parsed = DrivingLicenceMrzParser().tryParse([_documentNrCtrl.text]);
    if (_canContinue != could) {
      setState(() {});
    }
  }

  void _onContinuePressed() {
    final form = _manualEntryFormKey.currentState;
    if (form != null && form.validate()) {
      widget.onContinue(_parsed!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ManualEntryScaffold(
      appBarTitleKey: DocumentType.drivingLicence.scanTitleKey,
      formKey: _manualEntryFormKey,
      onChanged: _recomputeCanContinue,
      titleKey: "driving_licence.manual.title",
      explanationKey: "driving_licence.manual.explanation",
      tipKey: DocumentType.drivingLicence.manualTipKey,
      onContinue: _canContinue ? _onContinuePressed : null,
      onCancel: widget.onCancel,
      fields: [DrivingLicenceMrzInputField(controller: _documentNrCtrl)],
    );
  }
}
