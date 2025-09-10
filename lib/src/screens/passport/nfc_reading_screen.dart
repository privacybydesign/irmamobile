import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vcmrtd/vcmrtd.dart';

import '../../data/passport_repository.dart';
import '../../models/nfc_reading_state.dart';
import '../../models/passport_data_result.dart';
import '../../models/passport_error_info.dart';
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
  final VoidCallback? onRetryCheckNfc;
  final ValueChanged<PassportDataResult>? onComplete;
  final Uint8List? nonce;
  final String? sessionId;

  const NfcReadingScreen({
    required this.docNumber,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    this.onCancel,
    this.onRetryCheckNfc,
    this.onComplete,
    this.nonce,
    this.sessionId,
    super.key,
  });

  @override
  State<NfcReadingScreen> createState() => _NfcReadingScreenState();
}

class _NfcReadingScreenState extends State<NfcReadingScreen> implements PassportListener {
  final PassportRepository _repo = PassportRepository();

  var _isNfcAvailable = false;

  final List<String> _tips = <String>[
    'passport.nfc.tip_1',
    'passport.nfc.tip_2',
    'passport.nfc.tip_3',
  ];
  int _tipIndex = 0;
  Timer? _tipTimer;

  double _progress = 0.0;
  String _stateKey = 'passport.nfc.connecting';
  String _hintKey = 'passport.nfc.hold_near';

  @override
  void initState() {
    super.initState();
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
    });
    _initNFCState();
  }

  Future<void> _startReading() async {
    _progress = 0.0;
    _stateKey = 'passport.nfc.connecting';
    setState(() {});
    await _repo.readWithMRZ(
      documentNumber: widget.docNumber,
      birthDate: widget.dateOfBirth,
      expiryDate: widget.dateOfExpiry,
      countryCode: 'NLD',
      sessionId: widget.sessionId,
      nonce: widget.nonce,
      listener: this,
    );
  }

  Future<void> _initNFCState() async {
    bool isNfcAvailable;
    try {
      NfcStatus status = await NfcProvider.nfcStatus;
      isNfcAvailable = status == NfcStatus.enabled;
    } on PlatformException {
      isNfcAvailable = false;
    }

    if (!mounted) return;

    setState(() {
      _isNfcAvailable = isNfcAvailable;
    });

    if (_isNfcAvailable) {
      await _startReading();
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _repo.cancel();
    super.dispose();
  }

  @override
  void onStateChanged(NFCReadingState state) {
    switch (state) {
      case NFCReadingState.waiting:
      case NFCReadingState.connecting:
      case NFCReadingState.authenticating:
      case NFCReadingState.reading:
        _stateKey = 'passport.nfc.connecting';
        break;
      case NFCReadingState.error:
        break;
      case NFCReadingState.cancelling:
        _stateKey = 'passport.nfc.cancelling';
        break;
      case NFCReadingState.success:
        _stateKey = 'passport.nfc.success';
        break;
      case NFCReadingState.idle:
        _stateKey = 'passport.nfc.idle';
        break;
    }
  }

  @override
  void onMessage(String message) {
    setState(() {
      _stateKey = message;
    });
  }

  @override
  void onProgress(double value) {
    setState(() {
      _progress = value.clamp(0.0, 1.0);
    });
  }

  @override
  void onDataGroupRead(String name, String hex) {}

  @override
  void onAuthenticated() {}

  @override
  void onError(PassportErrorInfo error) {
    setState(() {
      _progress = 0.0;
      _stateKey = 'passport.nfc.error';
    });
  }

  @override
  void onCancelled() {
    widget.onCancel?.call();
  }

  @override
  void onComplete(PassportDataResult result) {
    widget.onComplete?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'passport.nfc.title',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _isNfcAvailable ? theme.success : theme.error,
                      shape: BoxShape.circle,
                    ),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      _isNfcAvailable ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TranslatedText(
                    _isNfcAvailable ? 'passport.nfc.nfc_enabled' : 'passport.nfc.nfc_disabled',
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isNfcAvailable
                      ? _ScanningContent(
                          theme: theme,
                          tipKey: _tips[_tipIndex],
                          tipIndex: _tipIndex,
                          progressPercent: (_progress * 100).clamp(0, 100).toDouble(),
                          statusKey: _stateKey,
                          hintKey: _hintKey,
                          key: ValueKey('scanning-$_tipIndex-$_progress'),
                        )
                      : _DisabledContent(theme: theme, key: const ValueKey('disabled'))),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isNfcAvailable
          ? IrmaBottomBar(
              alignment: IrmaBottomBarAlignment.vertical,
              secondaryButtonLabel: 'ui.cancel',
              onSecondaryPressed: () {
                _repo.cancel();
                widget.onCancel?.call();
              },
            )
          : IrmaBottomBar(
              alignment: IrmaBottomBarAlignment.vertical,
              primaryButtonLabel: 'ui.retry',
              onPrimaryPressed: () {
                widget.onRetryCheckNfc?.call();
                _startReading();
              },
              secondaryButtonLabel: 'ui.cancel',
              onSecondaryPressed: () {
                _repo.cancel();
                widget.onCancel?.call();
              },
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
    required this.progressPercent,
    required this.statusKey,
    this.hintKey,
    super.key,
  });

  final IrmaThemeData theme;
  final String tipKey;
  final int tipIndex;
  final double progressPercent;
  final String statusKey;
  final String? hintKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(tipIndex),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.nfc, size: 80, color: theme.link),
        SizedBox(height: theme.mediumSpacing),
        TranslatedText(statusKey, style: theme.textTheme.headlineMedium),
        SizedBox(height: theme.smallSpacing),
        TranslatedText(hintKey ?? '', style: theme.textTheme.bodyMedium),
        SizedBox(height: theme.mediumSpacing),
        IrmaLinearProgressIndicator(filledPercentage: progressPercent),
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
