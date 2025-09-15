import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/passport_issuer.dart';
import '../../data/passport_repository.dart';
import '../../models/nfc_reading_state.dart';
import '../../models/passport_data_result.dart';
import '../../providers/passport_repository_provider.dart';
import '../../theme/theme.dart';
import '../../util/handle_pointer.dart';
import '../../util/nonce_parser.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_linear_progresss_indicator.dart';
import '../../widgets/translated_text.dart';

class NfcReadingScreen extends ConsumerStatefulWidget {
  final String docNumber;
  final DateTime dateOfBirth;
  final DateTime dateOfExpiry;
  final String? countryCode;
  final VoidCallback? onCancel;
  final ValueChanged<PassportDataResult>? onComplete;

  const NfcReadingScreen({
    required this.docNumber,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    this.countryCode,
    this.onCancel,
    this.onComplete,
    super.key,
  });

  @override
  ConsumerState<NfcReadingScreen> createState() => _NfcReadingScreenState();
}

class _NfcReadingScreenState extends ConsumerState<NfcReadingScreen> {
  // FIXME: make this more dynamic...
  final _isNfcAvailable = true;

  void cancel() async {
    final userWantsCancel = await _showCancelDialog(context);

    if (userWantsCancel) {
      ref.read(passportReaderProvider.notifier).cancel();
    }
  }

  void startSession() async {
    final passportIssuer = ref.read(passportIssuerProvider);

    final NonceAndSessionId(:nonce, :sessionId) = await passportIssuer.startSessionAtPassportIssuer();

    await ref.read(passportReaderProvider.notifier).readWithMRZ(
          documentNumber: widget.docNumber,
          birthDate: widget.dateOfBirth,
          expiryDate: widget.dateOfExpiry,
          countryCode: widget.countryCode,
          sessionId: sessionId,
          nonce: stringToUint8List(nonce),
        );

    final state = ref.read(passportReaderProvider);

    if (state case PassportReadingSuccess(result: final result)) {
      try {
        final sessionPtr = await passportIssuer.startIrmaIssuanceSession(result);
        if (!mounted || sessionPtr == null) {
          return;
        }
        await handlePointer(context, sessionPtr);
      } catch (e) {
        debugPrint('issuance error: $e');
      }
    }
  }

  void retry() {
    ref.read(passportReaderProvider.notifier).cancel();
    startSession();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final passportState = ref.watch(passportReaderProvider);
    final uiState = passportReadingStateToUiState(passportState);

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
                          tipKey: uiState.tipKey,
                          progressPercent: (uiState.progress * 100).clamp(0, 100).toDouble(),
                          statusKey: uiState.stateKey,
                          hintKey: uiState.hintKey,
                          key: ValueKey('scanning-${uiState.tipKey}-${uiState.progress}'),
                        )
                      : _DisabledContent(theme: theme, key: const ValueKey('disabled'))),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isNfcAvailable
          ? IrmaBottomBar(
              alignment: IrmaBottomBarAlignment.vertical,
              primaryButtonLabel: uiState.stateKey == 'passport.nfc.error' ? 'ui.retry' : null,
              onPrimaryPressed: uiState.stateKey == 'passport.nfc.error' ? retry : null,
              secondaryButtonLabel: 'ui.cancel',
              onSecondaryPressed: cancel,
            )
          : IrmaBottomBar(
              alignment: IrmaBottomBarAlignment.vertical,
              primaryButtonLabel: 'ui.retry',
              onPrimaryPressed: retry,
              secondaryButtonLabel: 'ui.cancel',
              onSecondaryPressed: cancel,
            ),
    );
  }

  _UiState passportReadingStateToUiState(PassportReadingState state) {
    return switch (state) {
      PassportReadingPending() => _UiState(
          progress: 0.0,
          stateKey: 'passport.nfc.connecting',
          tipKey: 'passport.nfc.hold_near_photo_page',
          hintKey: 'passport.nfc.tip_2',
        ),
      PassportReadingInProgress(message: final hintKey, :final nfcState, :final progress) => switch (nfcState) {
          NFCReadingState.waiting || NFCReadingState.connecting => _UiState(
              progress: progress,
              stateKey: 'passport.nfc.connecting',
              tipKey: 'passport.nfc.tip_2',
              hintKey: hintKey,
            ),
          NFCReadingState.reading || NFCReadingState.authenticating => _UiState(
              progress: progress,
              stateKey: 'passport.nfc.connecting',
              tipKey: 'passport.nfc.tip_1',
              hintKey: hintKey,
            ),
          NFCReadingState.success => _UiState(
              progress: progress,
              stateKey: 'passport.nfc.success',
              tipKey: 'passport.nfc.tip_1',
              hintKey: hintKey,
            ),
          NFCReadingState.error => _UiState(
              progress: progress,
              stateKey: 'passport.nfc.error',
              tipKey: 'passport.nfc.tip_3',
              hintKey: hintKey,
            ),
          NFCReadingState.idle => _UiState(
              progress: progress,
              stateKey: 'passport.nfc.idle',
              tipKey: 'passport.nfc.tip_3',
              hintKey: hintKey,
            ),
          NFCReadingState.cancelling => _UiState(
              progress: progress,
              stateKey: 'passport.nfc.cancelling',
              tipKey: 'passport.nfc.tip_3',
              hintKey: hintKey,
            ),
        },
      PassportReadingSuccess() => _UiState(
          progress: 1,
          stateKey: 'passport.nfc.success',
          tipKey: 'passport.nfc.tip_3',
          hintKey: 'passport.nfc.tip_2',
        ),
      PassportReadingFailed() => _UiState(
          progress: 0,
          stateKey: 'passport.nfc.error',
          tipKey: 'passport.nfc.tip_3',
          hintKey: 'passport.nfc.error_generic',
        ),
      PassportReadingCancelled() => _UiState(
          progress: 0,
          stateKey: '',
          tipKey: '',
          hintKey: '',
        ),
      PassportReadingCancelling() => _UiState(
          progress: 0,
          stateKey: '',
          tipKey: '',
          hintKey: '',
        ),
      _ => throw Exception('unexpected state: $state'),
    };
  }
}

Future<bool> _showCancelDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const TranslatedText('passport.nfc.cancel_dialog.title'),
          content: const TranslatedText('passport.nfc.cancel_dialog.explanation'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const TranslatedText('passport.nfc.cancel_dialog.decline'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const TranslatedText('passport.nfc.cancel_dialog.confirm'),
            ),
          ],
        ),
      ) ??
      false;
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
    required this.progressPercent,
    required this.statusKey,
    this.hintKey,
    super.key,
  });

  final IrmaThemeData theme;
  final String tipKey;
  final double progressPercent;
  final String statusKey;
  final String? hintKey;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                key: ValueKey(tipKey),
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

class _UiState {
  final String tipKey;
  final double progress;
  final String stateKey;
  final String hintKey;

  _UiState({required this.tipKey, required this.progress, required this.stateKey, required this.hintKey});
}
