import "package:material_ui/material_ui.dart";
import "package:mrz_parser/mrz_parser.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/document_flow_footer.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "document_step_in_sheet.dart";
import "widgets/driving_licence_mrz_field.dart";
import "widgets/manual_entry_layout.dart";

/// Data returned on continue.
class DrivingLicenceMrzManualEntryData {
  final String documentNumber;
  final String version;
  final String randomData;
  final String configuration;
  final String countryCode;

  DrivingLicenceMrzManualEntryData({
    required this.documentNumber,
    required this.version,
    required this.randomData,
    required this.configuration,
    required this.countryCode,
  });
}

/// This screen is for when the camera doesn't work(?)
class DrivingLicenceMrzManualEntryScreen extends StatefulWidget {
  /// Now receives the collected data from the 3 fields.
  final void Function(DrivingLicenceMrzManualEntryData data) onContinue;
  final VoidCallback onCancel;

  const DrivingLicenceMrzManualEntryScreen({
    required this.onContinue,
    required this.onCancel,
    super.key,
  });

  @override
  State<DrivingLicenceMrzManualEntryScreen> createState() =>
      _DrivingLicencetMrzManualEntryScreenState();
}

class _DrivingLicencetMrzManualEntryScreenState
    extends State<DrivingLicenceMrzManualEntryScreen> {
  final _manualEntryFormKey = GlobalKey<FormState>();
  final _documentNrCtrl = TextEditingController();

  bool _canContinue = false; // soft validity during typing

  void _recomputeCanContinue() {
    final result = DrivingLicenceMrzParser().tryParse([_documentNrCtrl.text]);
    final ok = result != null;

    if (ok != _canContinue) {
      setState(() => _canContinue = ok);
    }
  }

  void _onContinuePressed() {
    final form = _manualEntryFormKey.currentState;
    if (form != null && form.validate()) {
      final result = DrivingLicenceMrzParser().tryParse([
        _documentNrCtrl.text,
      ])!;
      final data = DrivingLicenceMrzManualEntryData(
        documentNumber: result.documentNumber,
        version: result.version,
        randomData: result.randomData,
        configuration: result.configuration,
        countryCode: result.countryCode,
      );
      widget.onContinue(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: DocumentStepInSheet.of(context)
            ? Colors.transparent
            : palette.background,
        // In a sheet its bar has the title, back and close.
        appBar: DocumentStepInSheet.of(context)
            ? null
            : IrmaAppBar(titleTranslationKey: "driving_licence.scan.title"),
        body: SizedBox(
          height: .infinity,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Form(
              key: _manualEntryFormKey,
              onChanged: _recomputeCanContinue,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: ManualEntryLayout(
                    titleKey: "driving_licence.manual.title",
                    explanationKey: "driving_licence.manual.explanation",
                    tipKey: "document_flow.manual.tip_driving_licence",
                    fields: [
                      DrivingLicenceMrzInputField(controller: _documentNrCtrl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // In a sheet, the sheet's own buttons; its close button is the way out.
        bottomNavigationBar: DocumentStepInSheet.of(context)
            ? DocumentFlowFooter(
                buttons: [
                  DocumentFlowButton(
                    key: DocumentFlowButton.primaryKey,
                    labelKey: "ui.continue",
                    onPressed: _canContinue ? _onContinuePressed : null,
                  ),
                ],
              )
            : IrmaBottomBar(
                primaryButtonLabel: "ui.continue",
                onPrimaryPressed: _canContinue ? _onContinuePressed : null,
                secondaryButtonLabel: "ui.cancel",
                onSecondaryPressed: widget.onCancel,
              ),
      ),
    );
  }
}
