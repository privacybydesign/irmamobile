import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routing.dart';
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
import 'widgets/passport_animation.dart';

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

class _NfcReadingScreenState extends ConsumerState<NfcReadingScreen> with RouteAware {
  void cancel() async {
    final userWantsCancel = await _showCancelDialog(context);

    if (userWantsCancel) {
      ref.read(passportReaderProvider.notifier).cancel();
      widget.onCancel?.call();
    }
  }

  @override
  void didPopNext() {
    ref.read(passportReaderProvider.notifier).reset();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
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
    if (passportState is PassportReaderPending) {
      return _buildIntroductionScreen(context);
    }

    final uiState = passportReadingStateToUiState(passportState);

    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'passport.nfc.title',
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(child: _buildStatus(context, uiState)),
                  Flexible(child: PassportNfcScanningAnimation()),
                ],
              );
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(child: PassportNfcScanningAnimation()),
                SizedBox(height: theme.largeSpacing),
                Flexible(child: _buildStatus(context, uiState)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: uiState.stateKey == 'passport.nfc.error' ? 'ui.retry' : null,
        onPrimaryPressed: uiState.stateKey == 'passport.nfc.error' ? retry : null,
        secondaryButtonLabel: 'ui.cancel',
        onSecondaryPressed: cancel,
      ),
    );
  }

  Widget _buildNfcSection(BuildContext context, EdgeInsets padding, {bool disabled = false}) {
    final theme = IrmaTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundTertiary,
        borderRadius: BorderRadius.circular(20),
        border: BoxBorder.all(color: theme.tertiary),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nfc, size: 100, color: disabled ? theme.error : theme.link),
            SizedBox(height: theme.mediumSpacing),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(color: disabled ? theme.error : theme.success, shape: BoxShape.circle),
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Icon(disabled ? Icons.close : Icons.check, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                TranslatedText(disabled ? 'passport.nfc.nfc_disabled' : 'passport.nfc.nfc_enabled'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(BuildContext context, _UiState uiState) {
    final theme = IrmaTheme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Padding(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: _ScanningContent(
          tipKey: uiState.tipKey,
          progressPercent: (uiState.progress * 100).clamp(0, 100).toDouble(),
          statusKey: uiState.stateKey,
          key: ValueKey('scanning-${uiState.tipKey}-${uiState.progress}'),
        ),
      ),
    );
  }

  Widget _buildIntroductionScreen(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(titleTranslationKey: 'passport.nfc.title'),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
          child: OrientationBuilder(builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: TranslatedText(
                      'passport.nfc.introduction',
                      textAlign: TextAlign.start,
                    ),
                  ),
                  Flexible(child: PassportNfcScanningAnimation()),
                ],
              );
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                PassportNfcScanningAnimation(),
                SizedBox(height: theme.largeSpacing),
                TranslatedText(
                  'passport.nfc.introduction',
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'passport.nfc.start_scanning',
        onPrimaryPressed: startSession,
        secondaryButtonLabel: 'ui.cancel',
        onSecondaryPressed: cancel,
      ),
    );
  }

  Widget _buildNfcUnavailableScreen(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: IrmaAppBar(titleTranslationKey: 'passport.nfc.title'),
      body: SafeArea(
        child: Center(
          child: OrientationBuilder(builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: TranslatedText(
                      'passport.nfc.nfc_disabled_explanation',
                      textAlign: TextAlign.start,
                      maxLines: 4,
                    ),
                  ),
                  Flexible(
                    child: _buildNfcSection(
                      context,
                      EdgeInsets.symmetric(horizontal: theme.hugeSpacing, vertical: theme.smallSpacing),
                      disabled: true,
                    ),
                  ),
                ],
              );
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNfcSection(
                    context, EdgeInsets.symmetric(horizontal: theme.hugeSpacing, vertical: theme.largeSpacing),
                    disabled: true),
                SizedBox(height: theme.largeSpacing),
                TranslatedText(
                  'passport.nfc.nfc_disabled_explanation',
                  textAlign: TextAlign.center,
                  maxLines: 4,
                ),
              ],
            );
          }),
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
    final progress = progressForState(state);
    return switch (state) {
      PassportReaderPending() => _UiState(
          progress: progress,
          stateKey: 'passport.nfc.connecting',
          tipKey: 'passport.nfc.hold_near_photo_page',
        ),
      PassportReaderConnecting() => _UiState(
          progress: progress,
          stateKey: 'passport.nfc.connecting',
          tipKey: 'passport.nfc.tip_2',
        ),
      PassportReaderAuthenticating() => _UiState(
          progress: progress,
          stateKey: 'passport.nfc.connecting',
          tipKey: 'passport.nfc.tip_2',
        ),
      PassportReaderReadingCardAccess() => _UiState(
          progress: progress,
          stateKey: 'passport.nfc.reading_card_security',
          tipKey: 'passport.nfc.tip_3',
        ),
      PassportReaderReadingCardSecurity() => _UiState(
          progress: progress,
          stateKey: 'passport.nfc.reading_card_security',
          tipKey: 'passport.nfc.tip_3',
        ),
      PassportReaderReadingPassportData() => _UiState(
          progress: progress,
          stateKey: 'passport.nfc.reading_passport_data',
          tipKey: 'passport.nfc.tip_1',
        ),
      PassportReaderActiveAuthenticating() => _UiState(
          progress: progress,
          stateKey: 'passport.nfc.performing_security_verification',
          tipKey: 'passport.nfc.tip_1',
        ),
      PassportReaderSecurityVerification() => _UiState(
          progress: progress,
          stateKey: 'passport.nfc.performing_security_verification',
          tipKey: 'passport.nfc.tip_1',
        ),
      PassportReaderSuccess() => _UiState(
          progress: progress,
          stateKey: 'passport.nfc.success',
          tipKey: 'passport.nfc.success_explanation',
        ),
      PassportReaderFailed(:final error) => _UiState(
          progress: progress,
          stateKey: 'passport.nfc.error',
          tipKey: _readingErrorToHintKey(error),
        ),
      PassportReaderCancelling() => _UiState(
          progress: progress,
          stateKey: 'passport.nfc.cancelled',
          tipKey: '',
        ),
      PassportReaderCancelled() => _UiState(
          progress: progress,
          stateKey: 'passport.nfc.cancelled',
          tipKey: '',
        ),
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
      readingCardAccess: FlutterI18n.translate(context, 'passport.nfc.reading_card_security'),
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

class _ScanningContent extends StatelessWidget {
  const _ScanningContent({
    required this.tipKey,
    required this.progressPercent,
    required this.statusKey,
    super.key,
  });

  final String tipKey;
  final double progressPercent;
  final String statusKey;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    final textAlign = isLandscape ? TextAlign.start : TextAlign.center;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isLandscape ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        TranslatedText(
          statusKey,
          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20),
          textAlign: textAlign,
        ),
        SizedBox(height: theme.smallSpacing),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
          child: TranslatedText(
            tipKey,
            key: ValueKey(tipKey),
            textAlign: textAlign,
            maxLines: 3,
            style: TextStyle(
              color: theme.secondary,
              fontSize: 16,
              height: 1.4,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
        SizedBox(height: theme.largeSpacing),
        Padding(
          padding: isLandscape ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
          child: IrmaLinearProgressIndicator(filledPercentage: progressPercent),
        ),
      ],
    );
  }
}

class _UiState {
  final String tipKey;
  final double progress;
  final String stateKey;

  _UiState({required this.tipKey, required this.progress, required this.stateKey});
}
