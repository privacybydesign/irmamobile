import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/passport_issuer.dart';
import '../../data/passport_reader.dart';
import '../../models/passport_data_result.dart';
import '../../providers/passport_repository_provider.dart';
import '../../theme/theme.dart';
import '../../util/handle_pointer.dart';
import '../../util/nonce_parser.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_confirmation_dialog.dart';
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
  void cancel() async {
    final userWantsCancel = await _showCancelDialog(context);

    if (userWantsCancel) {
      ref.read(passportReaderProvider.notifier).cancel();
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => startSession());
  }

  void startSession() async {
    final passportIssuer = ref.read(passportIssuerProvider);

    final NonceAndSessionId(:nonce, :sessionId) = await passportIssuer.startSessionAtPassportIssuer();

    final result = await ref.read(passportReaderProvider.notifier).readWithMRZ(
          iosNfcMessages: _getTranslatedIosNfcMessages(),
          documentNumber: widget.docNumber,
          birthDate: widget.dateOfBirth,
          expiryDate: widget.dateOfExpiry,
          countryCode: widget.countryCode,
          sessionId: sessionId,
          nonce: stringToUint8List(nonce),
        );

    if (result != null) {
      try {
        // start the issuance session at the irma server
        final sessionPtr = await passportIssuer.startIrmaIssuanceSession(result);
        if (!mounted) {
          return;
        }

        // handle it like any other external issuance session
        await handlePointer(context, sessionPtr);
      } catch (e) {
        debugPrint('issuance error: $e');
      }
    } else {
      debugPrint('canceled passport irma issuance session because the passport data result is null');
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

    if (passportState is PassportReaderNfcUnavailable) {
      return _buildNfcUnavailableScreen(context);
    }

    final uiState = passportReadingStateToUiState(passportState);

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'passport.nfc.title',
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: theme.largeSpacing),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(color: theme.success, shape: BoxShape.circle),
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Icon(Icons.check, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                TranslatedText('passport.nfc.nfc_enabled'),
              ],
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Padding(
                  padding: EdgeInsets.all(theme.defaultSpacing),
                  child: _ScanningContent(
                    theme: theme,
                    tipKey: uiState.tipKey,
                    progressPercent: (uiState.progress * 100).clamp(0, 100).toDouble(),
                    statusKey: uiState.stateKey,
                    hintKey: uiState.hintKey,
                    key: ValueKey('scanning-${uiState.tipKey}-${uiState.progress}'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        alignment: IrmaBottomBarAlignment.vertical,
        primaryButtonLabel: uiState.stateKey == 'passport.nfc.error' ? 'ui.retry' : null,
        onPrimaryPressed: uiState.stateKey == 'passport.nfc.error' ? retry : null,
        secondaryButtonLabel: 'ui.cancel',
        onSecondaryPressed: cancel,
      ),
    );
  }

  Widget _buildNfcUnavailableScreen(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(titleTranslationKey: 'passport.nfc.title'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(color: theme.error, shape: BoxShape.circle),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  TranslatedText('passport.nfc.nfc_disabled'),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _DisabledContent(theme: theme, key: const ValueKey('disabled')),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        alignment: IrmaBottomBarAlignment.vertical,
        primaryButtonLabel: 'ui.retry',
        onPrimaryPressed: retry,
        secondaryButtonLabel: 'ui.cancel',
        onSecondaryPressed: cancel,
      ),
    );
  }

  _UiState passportReadingStateToUiState(PassportReaderState state) {
    return switch (state) {
      PassportReaderPending() => _UiState(
          progress: 0.0,
          stateKey: 'passport.nfc.connecting',
          tipKey: 'passport.nfc.hold_near_photo_page',
          hintKey: 'passport.nfc.tip_2',
        ),
      PassportReaderConnecting() => _UiState(
          progress: 0.0,
          stateKey: 'passport.nfc.connecting',
          tipKey: 'passport.nfc.tip_2',
          hintKey: 'passport.nfc.hold_near_photo_page',
        ),
      PassportReaderAuthenticating() => _UiState(
          progress: 0.1,
          stateKey: 'passport.nfc.connecting',
          tipKey: 'passport.nfc.tip_2',
          hintKey: 'passport.nfc.hold_near_photo_page',
        ),
      PassportReaderReadingCardAccess() => _UiState(
          progress: 0.2,
          stateKey: 'passport.nfc.reading_card_access',
          tipKey: 'passport.nfc.tip_3',
          hintKey: 'passport.nfc.tip_3',
        ),
      PassportReaderReadingCardSecurity() => _UiState(
          progress: 0.3,
          stateKey: 'passport.nfc.reading_card_security',
          tipKey: 'passport.nfc.tip_3',
          hintKey: 'passport.nfc.tip_3',
        ),
      PassportReaderReadingPassportData() => _UiState(
          progress: 0.4,
          stateKey: 'passport.nfc.reading_passport_data',
          tipKey: 'passport.nfc.tip_1',
          hintKey: 'passport.nfc.tip_1',
        ),
      PassportReaderActiveAuthenticating() => _UiState(
          progress: 0.9,
          stateKey: 'passport.nfc.performing_security_verification',
          tipKey: 'passport.nfc.tip_1',
          hintKey: 'passport.nfc.tip_1',
        ),
      PassportReaderSuccess() => _UiState(
          progress: 1,
          stateKey: 'passport.nfc.success',
          tipKey: 'passport.nfc.success_explanation',
          hintKey: 'passport.nfc.success_explanation',
        ),
      PassportReaderFailed(:final error) => _UiState(
          progress: 0,
          stateKey: 'passport.nfc.error',
          tipKey: _readingErrorToHintKey(error),
          hintKey: _readingErrorToHintKey(error),
        ),
      PassportReaderCancelling() => _UiState(progress: 0, stateKey: 'passport.nfc.cancelled', tipKey: '', hintKey: ''),
      PassportReaderCancelled() => _UiState(progress: 0, stateKey: 'passport.nfc.cancelled', tipKey: '', hintKey: ''),
      _ => throw Exception('unexpected state: $state'),
    };
  }

  IosNfcMessages _getTranslatedIosNfcMessages() {
    String progressFormatter(double progress) {
      const numStages = 10;
      final prog = (progress * numStages).toInt();
      return '🟢' * prog + '⚪️' * (numStages - prog);
    }

    return IosNfcMessages(
      progressFormatter: progressFormatter,
      holdNearPhotoPage: FlutterI18n.translate(context, 'passport.nfc.hold_near_photo_page'),
      cancelling: FlutterI18n.translate(context, 'passport.nfc.cancelling'),
      cancelled: FlutterI18n.translate(context, 'passport.nfc.cancelled'),
      connecting: FlutterI18n.translate(context, 'passport.nfc.connecting'),
      readingCardAccess: FlutterI18n.translate(context, 'passport.nfc.reading_card_access'),
      readingCardSecurity: FlutterI18n.translate(context, 'passport.nfc.reading_card_security'),
      authenticating: FlutterI18n.translate(context, 'passport.nfc.authenticating'),
      readingPassportData: FlutterI18n.translate(context, 'passport.nfc.reading_passport_data'),
      cancelledByUser: FlutterI18n.translate(context, 'passport.nfc.cancelled_by_user'),
      performingSecurityVerification: FlutterI18n.translate(context, 'passport.nfc.performing_security_verification'),
      completedSuccessfully: FlutterI18n.translate(context, 'passport.nfc.completed_successfully'),
      timeoutWaitingForTag: FlutterI18n.translate(context, 'passport.nfc.timeout_waiting_for_tag'),
      failedToInitiateSession: FlutterI18n.translate(context, 'passport.nfc.failed_initiate_session'),
      tagLostTryAgain: FlutterI18n.translate(context, 'passport.nfc.tag_lost_try_again'),
    );
  }
}

String _readingErrorToHintKey(PassportReadingError error) {
  return switch (error) {
    PassportReadingError.unknown => 'passport.nfc.error_generic',
    PassportReadingError.timeoutWaitingForTag => 'passport.nfc.timeout_waiting_for_tag',
    PassportReadingError.tagLost => 'passport.nfc.tag_lost_try_again',
    PassportReadingError.failedToInitiateSession => 'passport.nfc.failed_initiate_session',
    PassportReadingError.invalidatedByUser => '',
  };
}

Future<bool> _showCancelDialog(BuildContext context) async {
  return await showDialog(
          context: context,
          builder: (context) {
            return IrmaConfirmationDialog(
              titleTranslationKey: 'passport.nfc.cancel_dialog.title',
              contentTranslationKey: 'passport.nfc.cancel_dialog.explanation',
              cancelTranslationKey: 'passport.nfc.cancel_dialog.decline',
              confirmTranslationKey: 'passport.nfc.cancel_dialog.confirm',
              onCancelPressed: () => Navigator.of(context).pop(false),
              onConfirmPressed: () => Navigator.of(context).pop(true),
            );
          }) ??
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
        TranslatedText(
          statusKey,
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: theme.smallSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
          child: TranslatedText(hintKey ?? '', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ),
        SizedBox(height: theme.mediumSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.largeSpacing),
          child: IrmaLinearProgressIndicator(filledPercentage: progressPercent),
        ),
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
