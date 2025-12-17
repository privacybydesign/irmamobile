import "package:flutter/material.dart";
import "package:mrz_parser/mrz_parser.dart";

import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/translated_text.dart";
import "widgets/driving_licence_mrz_field.dart";

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
    final theme = IrmaTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.backgroundTertiary,
        appBar: IrmaAppBar(titleTranslationKey: "driving_licence.manual.title"),
        body: SizedBox(
          height: .infinity,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Form(
              key: _manualEntryFormKey,
              onChanged: _recomputeCanContinue,
              child: SafeArea(
                child: Padding(
                  padding: .all(theme.defaultSpacing),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      const TranslatedText(
                        "driving_licence.manual.explanation",
                      ),
                      SizedBox(height: theme.mediumSpacing),
                      DrivingLicenceMrzInputField(controller: _documentNrCtrl),
                      SizedBox(height: theme.largeSpacing),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: "ui.continue",
          onPrimaryPressed: _canContinue ? _onContinuePressed : null,
          secondaryButtonLabel: "ui.cancel",
          onSecondaryPressed: widget.onCancel,
        ),
      ),
    );
  }
}
