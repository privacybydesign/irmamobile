import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/translated_text.dart';
import 'widgets/date_input_field.dart';
import 'widgets/document_nr_input_field.dart';
import 'widgets/mzr_scanner.dart';

typedef MRZController = GlobalKey<MRZScannerState>;

/// Data returned on continue.
typedef ManualEntryData = ({
  String documentNr,
  DateTime dateOfBirth,
  DateTime expiryDate,
});

class ManualEntryScreen extends StatefulWidget {
  /// Now receives the collected data from the 3 fields.
  final void Function(ManualEntryData data) onContinue;
  final VoidCallback onCancel;

  const ManualEntryScreen({
    required this.onContinue,
    required this.onCancel,
    super.key,
  });

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _manualEntryFormKey = GlobalKey<FormState>();

  final _documentNrCtrl = TextEditingController();
  final _dateOfBirthCtrl = TextEditingController();
  final _expiryDateCtrl = TextEditingController();

  bool _canContinue = false; // soft validity during typing

  @override
  void initState() {
    super.initState();
    // Recompute soft validity whenever any field changes
    _documentNrCtrl.addListener(_recomputeCanContinue);
    _dateOfBirthCtrl.addListener(_recomputeCanContinue);
    _expiryDateCtrl.addListener(_recomputeCanContinue);
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

  @override
  void dispose() {
    _documentNrCtrl.dispose();
    _dateOfBirthCtrl.dispose();
    _expiryDateCtrl.dispose();
    super.dispose();
  }

  void _onContinuePressed() {
    final form = _manualEntryFormKey.currentState;
    if (form != null && form.validate()) {
      final data = (
        documentNr: _documentNrCtrl.text.trim(),
        dateOfBirth: _parseDate(_dateOfBirthCtrl.text.trim()),
        expiryDate: _parseDate(_expiryDateCtrl.text.trim()),
      );
      widget.onContinue(data);
    }
  }

  DateTime _parseDate(String input) {
    // assuming format dd-MM-yyyy
    final parts = input.split('-');
    if (parts.length != 3) {
      throw FormatException("Invalid date format: $input");
    }
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final keyboardIsActive = mediaQuery.viewInsets.bottom > 0;
    final isLandscape = mediaQuery.size.width > 450;

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(titleTranslationKey: 'passport.manual.title'),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Form(
                key: _manualEntryFormKey,
                onChanged: () {
                  _recomputeCanContinue();
                },
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(theme.defaultSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TranslatedText('passport.manual.explanation'),
                          SizedBox(height: theme.mediumSpacing),
                          DocumentNrInputField(controller: _documentNrCtrl),
                          SizedBox(height: theme.mediumSpacing),
                          DateInputField(
                            controller: _dateOfBirthCtrl,
                            fieldKey: const Key('passport_dob_field'),
                            labelI18nKey: 'passport.manual.fields.date_of_birth',
                            requiredI18nKey: 'passport.manual.fields.date_of_birth_required',
                            formatDate: (ctx, d) => "${d.day.toString().padLeft(2, '0')}-"
                                "${d.month.toString().padLeft(2, '0')}-"
                                '${d.year}',
                          ),
                          SizedBox(height: theme.mediumSpacing),
                          DateInputField(
                            controller: _expiryDateCtrl,
                            fieldKey: const Key('passport_expiry_date_field'),
                            labelI18nKey: 'passport.manual.fields.date_of_expiry',
                            requiredI18nKey: 'passport.manual.fields.date_of_expiry_required',
                            formatDate: (ctx, d) => "${d.day.toString().padLeft(2, '0')}-"
                                "${d.month.toString().padLeft(2, '0')}-"
                                '${d.year}',
                          ),
                        ],
                      ),
                    ),
                    if (!keyboardIsActive || !isLandscape) ...[
                      const Spacer(),
                      IrmaBottomBar(
                        primaryButtonLabel: 'ui.continue',
                        onPrimaryPressed: _canContinue ? _onContinuePressed : null,
                        secondaryButtonLabel: 'ui.cancel',
                        onSecondaryPressed: widget.onCancel,
                        alignment: IrmaBottomBarAlignment.vertical,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
