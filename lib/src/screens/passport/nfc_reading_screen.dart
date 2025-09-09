import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_linear_progresss_indicator.dart';
import '../../widgets/translated_text.dart';

enum _NfcUiState {
  disabled, // NFC off
  scanning, // NFC on, trying to connect/read
}

class NfcReadingScreen extends StatefulWidget {
  final String docNumber;
  final DateTime dateOfBirth;
  final DateTime dateOfExpiry;

  final VoidCallback? onCancel;

  /// UI-only: fired when the user taps "Opnieuw proberen" in the NFC-disabled state.
  /// Hook this up to your actual NFC re-check/init logic and call setState accordingly.
  final VoidCallback? onRetryCheckNfc;

  const NfcReadingScreen({
    required this.docNumber,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    this.onCancel,
    this.onRetryCheckNfc,
    super.key,
  });

  @override
  State<NfcReadingScreen> createState() => _NfcReadingScreenState();
}

class _NfcReadingScreenState extends State<NfcReadingScreen> {
  // ---- Simple UI state machine (no real NFC logic) ----
  _NfcUiState _state = _NfcUiState.scanning;

  // Expose simple setters you can call after wiring real NFC checks.
  void showDisabled() => setState(() => _state = _NfcUiState.disabled);
  void showScanning() => setState(() => _state = _NfcUiState.scanning);

  // ---- Rotating tips (only visible in scanning state) ----
  final List<String> _tips = <String>[
    'passport.nfc.tip_1',
    'passport.nfc.tip_2',
    'passport.nfc.tip_3',
  ];
  int _tipIndex = 0;
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final bool isDisabled = _state == _NfcUiState.disabled;

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'passport.nfc.title', // "Paspoort uitlezen"
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top row: “NFC ingeschakeld” (green) vs “NFC is uitgeschakeld” (red)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDisabled ? theme.error : theme.success,
                      shape: BoxShape.circle,
                    ),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      isDisabled ? Icons.close : Icons.check,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TranslatedText(
                    isDisabled ? 'passport.nfc.nfc_disabled' : 'passport.nfc.nfc_enabled',
                  ),
                ],
              ),
            ),

            // Middle content switches by state
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isDisabled
                    ? _DisabledContent(theme: theme, key: const ValueKey('disabled'))
                    : _ScanningContent(
                        theme: theme,
                        tipKey: _tips[_tipIndex],
                        tipIndex: _tipIndex,
                        key: ValueKey('scanning-$_tipIndex'),
                      ),
              ),
            ),
          ],
        ),
      ),

      // Bottom bar: when disabled show primary "Opnieuw proberen" + secondary "Annuleren".
      // When scanning, only show "Annuleren".
      bottomNavigationBar: isDisabled
          ? IrmaBottomBar(
              alignment: IrmaBottomBarAlignment.vertical,
              primaryButtonLabel: 'ui.retry', // "Opnieuw proberen"
              onPrimaryPressed: () {
                // UI-only hook; parent can re-check NFC and then call showScanning()/showDisabled()
                widget.onRetryCheckNfc?.call();
              },
              secondaryButtonLabel: 'ui.cancel',
              onSecondaryPressed: widget.onCancel,
            )
          : IrmaBottomBar(
              alignment: IrmaBottomBarAlignment.vertical,
              secondaryButtonLabel: 'ui.cancel',
              onSecondaryPressed: widget.onCancel,
            ),
    );
  }
}

class _DisabledContent extends StatelessWidget {
  const _DisabledContent({required this.theme, super.key});
  final IrmaThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nfc, size: 80, color: theme.error),
            SizedBox(height: theme.largeSpacing),
            // “Het uitlezen van je paspoort lukt niet ...”
            TranslatedText(
              'passport.nfc.nfc_disabled_explanation',
              textAlign: TextAlign.center,
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanningContent extends StatelessWidget {
  const _ScanningContent({
    required this.theme,
    required this.tipKey,
    required this.tipIndex,
    super.key,
  });

  final IrmaThemeData theme;
  final String tipKey;
  final int tipIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(tipIndex),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.nfc, size: 80, color: theme.link),
        SizedBox(height: theme.mediumSpacing),
        TranslatedText('passport.nfc.connecting'),
        SizedBox(height: theme.mediumSpacing),
        const IrmaLinearProgressIndicator(filledPercentage: 20),
        SizedBox(height: theme.largeSpacing),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SizedBox(
            height: 48,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: TranslatedText(
                tipKey,
                key: ValueKey(tipIndex),
                textAlign: TextAlign.center,
                maxLines: 3,
                style: TextStyle(
                  color: theme.secondary,
                  fontSize: 16,
                  height: 1.4,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
