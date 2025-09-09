import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_linear_progresss_indicator.dart';
import '../../widgets/translated_text.dart';

class NfcReadingScreen extends StatefulWidget {
  final String docNumber;
  final DateTime dateOfBirth;
  final DateTime dateOfExpiry;

  final VoidCallback? onCancel;

  const NfcReadingScreen({
    required this.docNumber,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    this.onCancel,
    super.key,
  });

  @override
  State<NfcReadingScreen> createState() => _NfcReadingScreenState();
}

class _NfcReadingScreenState extends State<NfcReadingScreen> {
  // Rotating tips
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

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'passport.nfc.title', // "Paspoort uitlezen"
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top: NFC enabled row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF15A94A), // green check bubble
                      shape: BoxShape.circle,
                    ),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(Icons.check, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  TranslatedText('passport.nfc.nfc_enabled'),
                ],
              ),
            ),

            // Middle: icon + "Verbinden"
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.nfc, size: 80, color: theme.link),
                  SizedBox(height: theme.mediumSpacing),
                  TranslatedText('passport.nfc.connecting'),
                  SizedBox(height: theme.mediumSpacing),
                  IrmaLinearProgressIndicator(
                    filledPercentage: 20, // drive this from your NFC state
                  ),
                  SizedBox(height: theme.largeSpacing),
                  // Animated tips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SizedBox(
                      height: 48,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                        child: TranslatedText(
                          _tips[_tipIndex],
                          key: ValueKey(_tipIndex),
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
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        secondaryButtonLabel: 'ui.cancel',
        onSecondaryPressed: widget.onCancel,
        alignment: IrmaBottomBarAlignment.vertical,
      ),
    );
  }
}
