import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
import "package:go_router/go_router.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../../package_name.dart";
import "../../../../routing.dart";
import "../../../models/mrz.dart";
import "../../../models/session.dart";
import "../../../providers/document_reader_providers.dart";
import "../../../providers/passport_issuer_provider.dart";
import "../../../sentry/sentry.dart";
import "../../../theme/theme.dart";
import "../../../util/handle_pointer.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_confirmation_dialog.dart";
import "../../../widgets/irma_dialog.dart";
import "../../../widgets/irma_linear_progresss_indicator.dart";
import "../../../widgets/translated_text.dart";
import "widgets/driving_licence_nfc_scanning_animation.dart";
import "widgets/id_card_nfc_scanning_animation.dart";
import "widgets/passport_nfc_scanning_animation.dart";

class NfcReadingTranslationKeys {
  final String cancelDialogTitle;
  final String cancelDialogExplanation;
  final String cancelDialogDecline;
  final String cancelDialogConfirm;
  final String error;
  final String errorGeneric;
  final String title;
  final String nfcDisabled;
  final String nfcEnabled;
  final String introduction;
  final String startScanning;
  final String nfcDisabledExplanation;
  final String holdNearPhotoPage;
  final String tip1;
  final String tip2;
  final String tip3;
  final String successExplanation;
  final String cancelledByUser;
  final String cancelled;
  final String cancelling;
  final String connecting;
  final String readingCardSecurity;
  final String readingDocumentData;
  final String authenticating;
  final String performingSecurityVerification;
  final String timeoutWaitingForTag;
  final String tagLostTryAgain;
  final String failedToInitiateSession;
  final String success;

  NfcReadingTranslationKeys({
    required this.cancelDialogTitle,
    required this.cancelDialogExplanation,
    required this.cancelDialogDecline,
    required this.cancelDialogConfirm,
    required this.error,
    required this.errorGeneric,
    required this.title,
    required this.nfcDisabled,
    required this.nfcEnabled,
    required this.introduction,
    required this.startScanning,
    required this.nfcDisabledExplanation,
    required this.holdNearPhotoPage,
    required this.tip1,
    required this.tip2,
    required this.tip3,
    required this.successExplanation,
    required this.cancelledByUser,
    required this.cancelled,
    required this.cancelling,
    required this.connecting,
    required this.readingCardSecurity,
    required this.readingDocumentData,
    required this.authenticating,
    required this.performingSecurityVerification,
    required this.timeoutWaitingForTag,
    required this.tagLostTryAgain,
    required this.failedToInitiateSession,
    required this.success,
  });
}

class NfcReadingScreen extends ConsumerStatefulWidget {
  final ScannedMrz mrz;
  final NfcReadingTranslationKeys translationKeys;
  final VoidCallback? onCancel;

  const NfcReadingScreen({
    required this.mrz,
    required this.translationKeys,
    this.onCancel,
    super.key,
  });

  @override
  ConsumerState<NfcReadingScreen> createState() => _NfcReadingScreenState();
}

class _NfcReadingScreenState extends ConsumerState<NfcReadingScreen>
    with RouteAware {
  String? issuanceError;

  Widget _getAnimation() {
    return switch (widget.mrz) {
      ScannedPassportMrz() => PassportNfcScanningAnimation(),
      ScannedDrivingLicenceMrz() => DrivingLicenceNfcScanningAnimation(),
      ScannedIdCardMrz() => IdCardNfcScanningAnimation(),
    };
  }

  void cancel() async {
    final userWantsCancel = await _showCancelDialog(
      context,
      titleTranslationKey: widget.translationKeys.cancelDialogTitle,
      contentTranslationKey: widget.translationKeys.cancelDialogExplanation,
      cancelTranslationKey: widget.translationKeys.cancelDialogDecline,
      confirmTranslationKey: widget.translationKeys.cancelDialogConfirm,
    );

    if (userWantsCancel && mounted) {
      _getDocumentReader().cancel();
      widget.onCancel?.call();
    }
  }

  @override
  void didPopNext() {
    if (_readDocumentReaderState() is! DocumentReaderFailed) {
      if (mounted) {
        _getDocumentReader().reset();
      }
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
    setState(() {
      issuanceError = null;
    });
    final passportIssuer = ref.read(passportIssuerProvider);

    final NonceAndSessionId(:nonce, :sessionId) = await passportIssuer
        .startSessionAtPassportIssuer();

    final result = await _getDocumentReader().readDocument(
      iosNfcMessages: _createIosNfcMessageMapper(),
      activeAuthenticationParams: NonceAndSessionId(
        nonce: nonce,
        sessionId: sessionId,
      ),
    );

    if (result != null) {
      final (pdr, rawDocData) = result;

      // make sure it's not a passport scanned as an id-card and vice versa...
      final error = _validateDocType(pdr);
      if (error != null) {
        setState(() {
          issuanceError = error;
        });
        return;
      }

      await _startIssuance(rawDocData);
    }
  }

  String? _validateDocType(DocumentData data) {
    switch (widget.mrz) {
      case ScannedIdCardMrz():
        final docType = (data as PassportData).mrz.documentCode;
        return docType == "I"
            ? null
            : "Cannot scan document with MRZ that starts with $docType as an ID-card";
      case ScannedPassportMrz():
        final docType = (data as PassportData).mrz.documentCode;
        return docType == "P"
            ? null
            : "Cannot scan document with MRZ that starts with $docType as passport";
      case ScannedDrivingLicenceMrz():
        return null;
    }
  }

  Future<void> _startIssuance(RawDocumentData result) async {
    final passportIssuer = ref.read(passportIssuerProvider);
    try {
      // start the issuance session at the irma server
      final sessionPtr = await passportIssuer.startIrmaIssuanceSession(
        result,
        switch (widget.mrz) {
          ScannedPassportMrz() => .passport,
          ScannedDrivingLicenceMrz() => .drivingLicence,
          ScannedIdCardMrz() => .identityCard,
        },
      );
      if (!mounted) {
        return;
      }

      // handle it like any other external issuance session
      await handlePointer(
        context,
        SessionPointer(
          protocol: .irma,
          u: sessionPtr.u,
          irmaqr: sessionPtr.irmaqr,
          continueOnSecondDevice: true,
        ),
      );
    } catch (e) {
      setState(() {
        issuanceError = e.toString();
      });
      if (kDebugMode) {
        debugPrint("issuance error: $e");
      }
    }
  }

  void retry() {
    _getDocumentReader().cancel();
    _startScanning();
  }

  @override
  Widget build(BuildContext context) {
    // an issuance error is different from a passport nfc scanning error
    if (issuanceError != null) {
      return _buildError(
        context,
        _UiState(
          stateKey: widget.translationKeys.error,
          tipKey: widget.translationKeys.errorGeneric,
          progress: 0,
        ),
        issuanceError!,
      );
    }

    final passportState = _watchDocumentReaderState();

    if (passportState is DocumentReaderNfcUnavailable) {
      return _buildNfcUnavailableScreen(context);
    }
    if (passportState is DocumentReaderPending) {
      return _buildIntroductionScreen(context);
    }

    final uiState = passportReadingStateToUiState(passportState);

    if (passportState case DocumentReaderFailed(:final logs)) {
      return _buildError(context, uiState, logs);
    }

    if (passportState is DocumentReaderCancelled) {
      return _buildCancelled(context, uiState);
    }

    return _NfcScaffold(
      titleTranslationKey: widget.translationKeys.title,
      instruction: _buildStatus(context, uiState),
      illustration: _getAnimation(),
      bottomNavigationBar: IrmaBottomBar(
        secondaryButtonLabel: "ui.cancel",
        onSecondaryPressed: cancel,
      ),
    );
  }

  Widget _buildError(BuildContext context, _UiState uiState, String logs) {
    final theme = IrmaTheme.of(context);
    final isPortrait = MediaQuery.orientationOf(context) == .portrait;

    return _NfcScaffold(
      titleTranslationKey: widget.translationKeys.title,
      instruction: Column(
        crossAxisAlignment: isPortrait ? .center : .start,
        mainAxisAlignment: .center,
        mainAxisSize: .min,
        children: [
          _OrientationAwareTranslatedText(
            uiState.stateKey,
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20),
          ),
          SizedBox(height: theme.defaultSpacing),
          _OrientationAwareTranslatedText(uiState.tipKey),
          SizedBox(height: theme.defaultSpacing),
          GestureDetector(
            onTap: () {
              _showLogsDialog(context, logs);
            },
            child: _OrientationAwareTranslatedText(
              "error.button_show_error",
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: .underline,
                color: theme.link,
              ),
            ),
          ),
        ],
      ),
      illustration: Padding(
        padding: .all(theme.defaultSpacing),
        child: SvgPicture.asset(
          yiviAsset("error/general_error_illustration.svg"),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "ui.retry",
        onPrimaryPressed: retry,
        secondaryButtonLabel: "ui.cancel",
        onSecondaryPressed: cancel,
      ),
    );
  }

  Widget _buildCancelled(BuildContext context, _UiState uiState) {
    final theme = IrmaTheme.of(context);
    return _NfcScaffold(
      titleTranslationKey: widget.translationKeys.title,
      instruction: _TitleAndBody(
        titleKey: uiState.stateKey,
        bodyKey: uiState.tipKey,
      ),
      illustration: Padding(
        padding: .all(theme.defaultSpacing),
        child: SvgPicture.asset(
          yiviAsset("error/general_error_illustration.svg"),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "ui.retry",
        onPrimaryPressed: retry,
        secondaryButtonLabel: "ui.cancel",
        onSecondaryPressed: cancel,
      ),
    );
  }

  Widget _buildNfcSection(
    BuildContext context,
    EdgeInsets padding, {
    bool disabled = false,
  }) {
    final theme = IrmaTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundTertiary,
        borderRadius: .circular(20),
        border: .all(color: theme.tertiary),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Flexible(
              child: Icon(
                Icons.nfc,
                size: 100,
                color: disabled ? theme.error : theme.link,
              ),
            ),
            SizedBox(height: theme.mediumSpacing),
            Row(
              mainAxisSize: .min,
              crossAxisAlignment: .center,
              mainAxisAlignment: .center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: disabled ? theme.error : theme.success,
                    shape: .circle,
                  ),
                  width: 40,
                  height: 40,
                  alignment: .center,
                  child: Icon(
                    disabled ? Icons.close : Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                TranslatedText(
                  disabled
                      ? widget.translationKeys.nfcDisabled
                      : widget.translationKeys.nfcEnabled,
                ),
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
        padding: .all(theme.defaultSpacing),
        child: _ScanningContent(
          tipKey: uiState.tipKey,
          progressPercent: (uiState.progress * 100).clamp(0, 100).toDouble(),
          statusKey: uiState.stateKey,
          key: ValueKey("scanning-${uiState.tipKey}-${uiState.progress}"),
        ),
      ),
    );
  }

  Widget _buildIntroductionScreen(BuildContext context) {
    return _NfcScaffold(
      titleTranslationKey: widget.translationKeys.title,
      instruction: _OrientationAwareTranslatedText(
        widget.translationKeys.introduction,
      ),
      illustration: _getAnimation(),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: widget.translationKeys.startScanning,
        onPrimaryPressed: _startScanning,
        secondaryButtonLabel: "ui.cancel",
        onSecondaryPressed: cancel,
      ),
    );
  }

  Widget _buildNfcUnavailableScreen(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return _NfcScaffold(
      titleTranslationKey: widget.translationKeys.title,
      instruction: _OrientationAwareTranslatedText(
        widget.translationKeys.nfcDisabledExplanation,
      ),
      illustration: Padding(
        padding: .all(theme.defaultSpacing),
        child: _buildNfcSection(
          context,
          .symmetric(horizontal: theme.largeSpacing),
          disabled: true,
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "ui.retry",
        onPrimaryPressed: retry,
        secondaryButtonLabel: "ui.cancel",
        onSecondaryPressed: cancel,
      ),
    );
  }

  _UiState passportReadingStateToUiState(DocumentReaderState state) {
    final progress = progressForState(state);
    final stateKey = _getTranslationKeyForState(state);
    final tipKey = _getTipKeyForState(state);

    return _UiState(tipKey: tipKey, progress: progress, stateKey: stateKey);
  }

  DocumentReaderState _readDocumentReaderState() {
    return ref.read(switch (widget.mrz) {
      ScannedPassportMrz() => passportReaderProvider(
        widget.mrz as ScannedPassportMrz,
      ),
      ScannedDrivingLicenceMrz() => drivingLicenceReaderProvider(
        widget.mrz as ScannedDrivingLicenceMrz,
      ),
      ScannedIdCardMrz() => idCardReaderProvider(
        widget.mrz as ScannedIdCardMrz,
      ),
    });
  }

  DocumentReaderState _watchDocumentReaderState() {
    return ref.watch(switch (widget.mrz) {
      ScannedPassportMrz() => passportReaderProvider(
        widget.mrz as ScannedPassportMrz,
      ),
      ScannedDrivingLicenceMrz() => drivingLicenceReaderProvider(
        widget.mrz as ScannedDrivingLicenceMrz,
      ),
      ScannedIdCardMrz() => idCardReaderProvider(
        widget.mrz as ScannedIdCardMrz,
      ),
    });
  }

  DocumentReader _getDocumentReader() {
    return ref.read(
      switch (widget.mrz) {
        ScannedPassportMrz() => passportReaderProvider(
          widget.mrz as ScannedPassportMrz,
        ),
        ScannedDrivingLicenceMrz() => drivingLicenceReaderProvider(
          widget.mrz as ScannedDrivingLicenceMrz,
        ),
        ScannedIdCardMrz() => idCardReaderProvider(
          widget.mrz as ScannedIdCardMrz,
        ),
      }.notifier,
    );
  }

  String _getTipKeyForState(DocumentReaderState state) {
    return switch (state) {
      DocumentReaderPending() => widget.translationKeys.holdNearPhotoPage,
      DocumentReaderConnecting() => widget.translationKeys.tip2,
      DocumentReaderAuthenticating() => widget.translationKeys.tip2,
      DocumentReaderReadingCOM() => widget.translationKeys.tip3,
      DocumentReaderReadingCardAccess() => widget.translationKeys.tip3,
      DocumentReaderReadingDataGroup() => widget.translationKeys.tip1,
      DocumentReaderReadingSOD() => widget.translationKeys.tip2,
      DocumentReaderActiveAuthentication() => widget.translationKeys.tip1,
      DocumentReaderSuccess() => widget.translationKeys.successExplanation,
      DocumentReaderFailed(:final error) => _readingErrorToHintKey(error),
      DocumentReaderCancelling() => widget.translationKeys.cancelledByUser,
      DocumentReaderCancelled() => widget.translationKeys.cancelledByUser,
      _ => throw Exception("unexpected state: $state"),
    };
  }

  String _getTranslationKeyForState(DocumentReaderState state) {
    return switch (state) {
      DocumentReaderPending() => widget.translationKeys.holdNearPhotoPage,
      DocumentReaderCancelled() => widget.translationKeys.cancelled,
      DocumentReaderCancelling() => widget.translationKeys.cancelledByUser,
      DocumentReaderFailed() => widget.translationKeys.error,
      DocumentReaderConnecting() => widget.translationKeys.connecting,
      DocumentReaderReadingCardAccess() =>
        widget.translationKeys.readingCardSecurity,
      DocumentReaderReadingCOM() => widget.translationKeys.readingDocumentData,
      DocumentReaderAuthenticating() => widget.translationKeys.authenticating,
      DocumentReaderReadingDataGroup() =>
        widget.translationKeys.readingDocumentData,
      DocumentReaderReadingSOD() => widget.translationKeys.readingDocumentData,
      DocumentReaderActiveAuthentication() =>
        widget.translationKeys.performingSecurityVerification,
      DocumentReaderSuccess() => widget.translationKeys.success,
      _ => "",
    };
  }

  IosNfcMessageMapper _createIosNfcMessageMapper() {
    String progressFormatter(double progress) {
      const numStages = 10;
      final prog = (progress * numStages).toInt();
      return "🟢" * prog + "⚪️" * (numStages - prog);
    }

    return (state) {
      final progress = progressFormatter(progressForState(state));

      final message = FlutterI18n.translate(
        context,
        _getTranslationKeyForState(state),
      );
      return "$progress\n$message";
    };
  }

  String _readingErrorToHintKey(DocumentReadingError error) {
    return switch (error) {
      .unknown => widget.translationKeys.errorGeneric,
      .timeoutWaitingForTag => widget.translationKeys.timeoutWaitingForTag,
      .tagLost => widget.translationKeys.tagLostTryAgain,
      .failedToInitiateSession =>
        widget.translationKeys.failedToInitiateSession,
      .invalidatedByUser => "",
    };
  }
}

Future _showLogsDialog(BuildContext context, String logs) async {
  return showDialog(
    context: context,
    builder: (context) {
      final theme = IrmaTheme.of(context);
      return YiviDialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: .min,
            mainAxisAlignment: .spaceBetween,
            crossAxisAlignment: .start,
            children: [
              IrmaAppBar(
                titleTranslationKey: "error.details_title",
                leading: null,
              ),
              Row(
                mainAxisSize: .max,
                mainAxisAlignment: .end,
                children: [
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: logs));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Copied to clipboard!")),
                      );
                    },
                    icon: Icon(Icons.copy),
                  ),
                ],
              ),
              Flexible(
                fit: .loose,
                child: SingleChildScrollView(
                  padding: .all(theme.defaultSpacing),
                  child: Text(logs),
                ),
              ),
              IrmaBottomBar(
                primaryButtonLabel: "error.button_send_to_irma",
                secondaryButtonLabel: "error.button_ok",
                onPrimaryPressed: () async {
                  reportError(
                    Exception(logs),
                    StackTrace.current,
                    userInitiated: true,
                  );
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
    final isPortrait = MediaQuery.orientationOf(context) == .portrait;
    return Column(
      crossAxisAlignment: isPortrait ? .center : .start,
      mainAxisAlignment: .center,
      mainAxisSize: .min,
      children: [
        _OrientationAwareTranslatedText(
          titleKey,
          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20),
        ),
        SizedBox(height: theme.defaultSpacing),
        _OrientationAwareTranslatedText(bodyKey),
      ],
    );
  }
}

class _NfcScaffold extends StatelessWidget {
  const _NfcScaffold({
    required this.titleTranslationKey,
    required this.instruction,
    required this.illustration,
    required this.bottomNavigationBar,
  });

  final String titleTranslationKey;
  final Widget instruction;
  final Widget illustration;
  final Widget bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: IrmaAppBar(titleTranslationKey: titleTranslationKey),
      body: SafeArea(
        child: Center(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == .landscape) {
                return Row(
                  mainAxisAlignment: .spaceEvenly,
                  crossAxisAlignment: .center,
                  children: [
                    Flexible(child: instruction),
                    Flexible(child: illustration),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: .center,
                mainAxisAlignment: .center,
                mainAxisSize: .max,
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
    final isPortrait = MediaQuery.orientationOf(context) == .portrait;
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: isPortrait
          ? .symmetric(horizontal: theme.defaultSpacing)
          : .zero,
      child: TranslatedText(
        translationKey,
        textAlign: isPortrait ? .center : .start,
        style: style,
      ),
    );
  }
}

Future<bool> _showCancelDialog(
  BuildContext context, {
  required String titleTranslationKey,
  required String contentTranslationKey,
  required String cancelTranslationKey,
  required String confirmTranslationKey,
}) async {
  return await showDialog(
        context: context,
        builder: (context) {
          return IrmaConfirmationDialog(
            titleTranslationKey: titleTranslationKey,
            contentTranslationKey: contentTranslationKey,
            cancelTranslationKey: cancelTranslationKey,
            confirmTranslationKey: confirmTranslationKey,
            onCancelPressed: () => Navigator.of(context).pop(false),
            onConfirmPressed: () => Navigator.of(context).pop(true),
          );
        },
      ) ??
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
    final isLandscape = MediaQuery.orientationOf(context) == .landscape;

    final textAlign = isLandscape ? TextAlign.start : TextAlign.center;

    return Column(
      mainAxisAlignment: .start,
      mainAxisSize: .min,
      crossAxisAlignment: isLandscape ? .start : .center,
      children: [
        TranslatedText(
          statusKey,
          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20),
          textAlign: textAlign,
        ),
        SizedBox(height: theme.smallSpacing),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: TranslatedText(
            tipKey,
            key: ValueKey(tipKey),
            textAlign: textAlign,
            maxLines: 3,
            style: TextStyle(
              color: theme.secondary,
              fontSize: 16,
              height: 1.4,
              overflow: .visible,
            ),
          ),
        ),
        SizedBox(height: theme.largeSpacing),
        Padding(
          padding: isLandscape
              ? .zero
              : .symmetric(horizontal: theme.defaultSpacing),
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

  _UiState({
    required this.tipKey,
    required this.progress,
    required this.stateKey,
  });
}
