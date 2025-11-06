import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:vcmrtd/vcmrtd.dart';

import '../../../routing.dart';
import '../../models/protocol.dart';
import '../../models/session.dart';
import '../../providers/passport_issuer_provider.dart';
import '../../providers/passport_reader_provider.dart';
import '../../sentry/sentry.dart';
import '../../theme/theme.dart';
import '../../util/handle_pointer.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_confirmation_dialog.dart';
import '../../widgets/irma_dialog.dart';
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
    if (ref.read(passportReaderProvider) is! PassportReaderFailed) {
      ref.read(passportReaderProvider.notifier).reset();
    }
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

  void _startScanning() async {
    final passportIssuer = ref.read(passportIssuerProvider);

    final NonceAndSessionId(:nonce, :sessionId) = await passportIssuer.startSessionAtPassportIssuer();

    final result = await ref.read(passportReaderProvider.notifier).readWithMRZ(
          iosNfcMessages: _createIosNfcMessageMapper(),
          documentNumber: widget.docNumber,
          birthDate: widget.dateOfBirth,
          expiryDate: widget.dateOfExpiry,
          countryCode: widget.countryCode,
          activeAuthenticationParams: NonceAndSessionId(nonce: nonce, sessionId: sessionId),
        );

    if (result != null) {
      final (pdr, _) = result;
      await _startIssuance(pdr);
    }
  }

  Future<void> _startIssuance(PassportDataResult result) async {
    final passportIssuer = ref.read(passportIssuerProvider);
    try {
      // start the issuance session at the irma server
      final sessionPtr = await passportIssuer.startIrmaIssuanceSession(result);
      if (!mounted) {
        return;
      }

      // handle it like any other external issuance session
      await handlePointer(
        context,
        SessionPointer(
            u: sessionPtr.u, irmaqr: sessionPtr.irmaqr, protocol: Protocol.irma, continueOnSecondDevice: true),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('issuance error: $e');
      }
    }
  }

  void retry() {
    ref.read(passportReaderProvider.notifier).cancel();
    _startScanning();
  }

  @override
  Widget build(BuildContext context) {
    final passportState = ref.watch(passportReaderProvider);

    if (passportState is PassportReaderNfcUnavailable) {
      return _buildNfcUnavailableScreen(context);
    }
    if (passportState is PassportReaderPending) {
      return _buildIntroductionScreen(context);
    }

    final uiState = passportReadingStateToUiState(passportState);

    if (passportState case PassportReaderFailed(:final logs)) {
      return _buildError(context, uiState, logs);
    }

    if (passportState is PassportReaderCancelled) {
      return _buildCancelled(context, uiState);
    }

    return _NfcScaffold(
      instruction: _buildStatus(context, uiState),
      illustration: PassportNfcScanningAnimation(),
      bottomNavigationBar: IrmaBottomBar(
        secondaryButtonLabel: 'ui.cancel',
        onSecondaryPressed: cancel,
      ),
    );
  }

  Widget _buildError(BuildContext context, _UiState uiState, String logs) {
    final theme = IrmaTheme.of(context);
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;

    return _NfcScaffold(
      instruction: Column(
        crossAxisAlignment: isPortrait ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _OrientationAwareTranslatedText(uiState.stateKey, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20)),
          SizedBox(height: theme.defaultSpacing),
          _OrientationAwareTranslatedText(uiState.tipKey),
          SizedBox(height: theme.defaultSpacing),
          GestureDetector(
            onTap: () {
              _showLogsDialog(context, logs);
            },
            child: _OrientationAwareTranslatedText(
              'error.button_show_error',
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: TextDecoration.underline,
                color: theme.link,
              ),
            ),
          ),
        ],
      ),
      illustration: Padding(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SvgPicture.asset('assets/error/general_error_illustration.svg'),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'ui.retry',
        onPrimaryPressed: retry,
        secondaryButtonLabel: 'ui.cancel',
        onSecondaryPressed: cancel,
      ),
    );
  }

  Widget _buildCancelled(BuildContext context, _UiState uiState) {
    final theme = IrmaTheme.of(context);
    return _NfcScaffold(
      instruction: _TitleAndBody(titleKey: uiState.stateKey, bodyKey: uiState.tipKey),
      illustration: Padding(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SvgPicture.asset('assets/error/general_error_illustration.svg'),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'ui.retry',
        onPrimaryPressed: retry,
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
            Flexible(child: Icon(Icons.nfc, size: 100, color: disabled ? theme.error : theme.link)),
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
    return _NfcScaffold(
      instruction: _OrientationAwareTranslatedText('passport.nfc.introduction'),
      illustration: PassportNfcScanningAnimation(),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'passport.nfc.start_scanning',
        onPrimaryPressed: _startScanning,
        secondaryButtonLabel: 'ui.cancel',
        onSecondaryPressed: cancel,
      ),
    );
  }

  Widget _buildNfcUnavailableScreen(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return _NfcScaffold(
      instruction: _OrientationAwareTranslatedText('passport.nfc.nfc_disabled_explanation'),
      illustration: Padding(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: _buildNfcSection(context, EdgeInsets.symmetric(horizontal: theme.largeSpacing), disabled: true),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'ui.retry',
        onPrimaryPressed: retry,
        secondaryButtonLabel: 'ui.cancel',
        onSecondaryPressed: cancel,
      ),
    );
  }

  _UiState passportReadingStateToUiState(PassportReaderState state) {
    final progress = progressForState(state);
    final stateKey = _getTranslationKeyForState(state);

    return switch (state) {
      PassportReaderPending() => _UiState(
          progress: progress,
          stateKey: stateKey,
          tipKey: 'passport.nfc.hold_near_photo_page',
        ),
      PassportReaderConnecting() => _UiState(
          progress: progress,
          stateKey: stateKey,
          tipKey: 'passport.nfc.tip_2',
        ),
      PassportReaderAuthenticating() => _UiState(
          progress: progress,
          stateKey: stateKey,
          tipKey: 'passport.nfc.tip_2',
        ),
      PassportReaderReadingCOM() => _UiState(
          progress: progress,
          stateKey: stateKey,
          tipKey: 'passport.nfc.tip_3',
        ),
      PassportReaderReadingCardAccess() => _UiState(
          progress: progress,
          stateKey: stateKey,
          tipKey: 'passport.nfc.tip_3',
        ),
      PassportReaderReadingDataGroup() => _UiState(
          progress: progress,
          stateKey: stateKey,
          tipKey: 'passport.nfc.tip_1',
        ),
      PassportReaderReadingSOD() => _UiState(
          progress: progress,
          stateKey: stateKey,
          tipKey: 'passport.nfc.tip_2',
        ),
      PassportReaderActiveAuthentication() => _UiState(
          progress: progress,
          stateKey: stateKey,
          tipKey: 'passport.nfc.tip_1',
        ),
      PassportReaderSuccess() => _UiState(
          progress: progress,
          stateKey: stateKey,
          tipKey: 'passport.nfc.success_explanation',
        ),
      PassportReaderFailed(:final error) => _UiState(
          progress: progress,
          stateKey: stateKey,
          tipKey: _readingErrorToHintKey(error),
        ),
      PassportReaderCancelling() => _UiState(
          progress: progress,
          stateKey: stateKey,
          tipKey: 'passport.nfc.cancelled_by_user',
        ),
      PassportReaderCancelled() => _UiState(
          progress: progress,
          stateKey: stateKey,
          tipKey: 'passport.nfc.cancelled_by_user',
        ),
      _ => throw Exception('unexpected state: $state'),
    };
  }

  String _getTranslationKeyForState(PassportReaderState state) {
    return switch (state) {
      PassportReaderPending() => 'passport.nfc.hold_near_photo_page',
      PassportReaderCancelled() => 'passport.nfc.cancelled',
      PassportReaderCancelling() => 'passport.nfc.cancelling',
      PassportReaderFailed() => 'passport.nfc.error',
      PassportReaderConnecting() => 'passport.nfc.connecting',
      PassportReaderReadingCardAccess() => 'passport.nfc.reading_card_security',
      PassportReaderReadingCOM() => 'passport.nfc.reading_passport_data',
      PassportReaderAuthenticating() => 'passport.nfc.authenticating',
      PassportReaderReadingDataGroup() => 'passport.nfc.reading_passport_data',
      PassportReaderReadingSOD() => 'passport.nfc.reading_passport_data',
      PassportReaderActiveAuthentication() => 'passport.nfc.performing_security_verification',
      PassportReaderSuccess() => 'passport.nfc.success',
      _ => '',
    };
  }

  IosNfcMessageMapper _createIosNfcMessageMapper() {
    String progressFormatter(double progress) {
      const numStages = 10;
      final prog = (progress * numStages).toInt();
      return '🟢' * prog + '⚪️' * (numStages - prog);
    }

    final ios16OrHigher = _isiOS26OrHigher();

    return (state) {
      final progress = progressFormatter(progressForState(state));

      // on iOS 26 only one line is shown, so we'll use that for progress
      if (ios16OrHigher) {
        return progress;
      }

      // on lower iOS versions a second line can be shown, so we'll use that for showing a message
      final message = FlutterI18n.translate(context, _getTranslationKeyForState(state));
      return '$progress\n$message';
    };
  }
}

bool _isiOS26OrHigher() {
  if (!Platform.isIOS) return false;

  final match = RegExp(r'iOS (\d+)(?:\.(\d+))?').firstMatch(Platform.operatingSystemVersion);
  if (match == null) return false;

  final major = int.tryParse(match.group(1) ?? '0') ?? 0;
  return major >= 26; // replace with 26 or whichever major version you want
}

Future _showLogsDialog(BuildContext context, String logs) async {
  return showDialog(
    context: context,
    builder: (context) {
      final theme = IrmaTheme.of(context);
      return YiviDialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IrmaAppBar(
                titleTranslationKey: 'error.details_title',
                leading: null,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: logs));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied to clipboard!')),
                      );
                    },
                    icon: Icon(Icons.copy),
                  ),
                ],
              ),
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(theme.defaultSpacing),
                  child: Text(logs),
                ),
              ),
              IrmaBottomBar(
                primaryButtonLabel: 'error.button_send_to_irma',
                secondaryButtonLabel: 'error.button_ok',
                onPrimaryPressed: () async {
                  reportError(Exception(logs), StackTrace.current, userInitiated: true);
                  if (context.mounted) {
                    context.pop();
                  }
                },
                onSecondaryPressed: () {
                  context.pop();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _TitleAndBody extends StatelessWidget {
  const _TitleAndBody({required this.titleKey, required this.bodyKey});

  final String titleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    return Column(
      crossAxisAlignment: isPortrait ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _OrientationAwareTranslatedText(titleKey, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20)),
        SizedBox(height: theme.defaultSpacing),
        _OrientationAwareTranslatedText(bodyKey),
      ],
    );
  }
}

class _NfcScaffold extends StatelessWidget {
  const _NfcScaffold({
    required this.instruction,
    required this.illustration,
    required this.bottomNavigationBar,
  });

  final Widget instruction;
  final Widget illustration;
  final Widget bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: IrmaAppBar(titleTranslationKey: 'passport.nfc.title'),
      body: SafeArea(
        child: Center(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(child: instruction),
                    Flexible(child: illustration),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Flexible(child: illustration),
                  SizedBox(height: theme.largeSpacing),
                  Flexible(child: instruction),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _OrientationAwareTranslatedText extends StatelessWidget {
  const _OrientationAwareTranslatedText(this.translationKey, {this.style});

  final String translationKey;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    final theme = IrmaTheme.of(context);
    final alignment = isPortrait ? TextAlign.center : TextAlign.start;
    final insets = isPortrait ? EdgeInsets.symmetric(horizontal: theme.defaultSpacing) : EdgeInsets.zero;

    return Padding(
      padding: insets,
      child: TranslatedText(translationKey, textAlign: alignment, style: style),
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
