import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show ProviderListenable;
import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../../package_name.dart";
import "../../../../routing.dart";
import "../../../../yivi_core.dart";
import "../../../models/session.dart";
import "../../../providers/document_reader_providers.dart";
import "../../../providers/nfc_availability_provider.dart";
import "../../../providers/nfc_settings_provider.dart";
import "../../../providers/passport_issuer_provider.dart";
import "../../../theme/theme.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/handle_pointer.dart";
import "../../../util/navigation.dart";
import "../../../util/privacy_screen.dart";
import "../../../widgets/document_flow_footer.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_confirmation_dialog.dart";
import "../../../widgets/translated_text.dart";
import "document_step_in_sheet.dart";
import "document_translation_keys.dart";
import "face_verification_intro_screen.dart";
import "widgets/nfc_error_dialog.dart";
import "widgets/nfc_stage_pictures.dart";
import "widgets/nfc_stage_view.dart";

class NfcReadingTranslationKeys {
  final String cancelDialogTitle;
  final String cancelDialogExplanation;
  final String cancelDialogDecline;
  final String cancelDialogConfirm;
  final String error;
  final String errorGeneric;
  final String title;
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

  /// Shows the face check's intro and says whether the user starts it. In a
  /// sheet it opens as the sheet's next screen; by default full-screen.
  final Future<bool> Function(BuildContext context)? faceIntro;

  const NfcReadingScreen({
    required this.mrz,
    required this.translationKeys,
    this.onCancel,
    this.faceIntro,
    super.key,
  });

  @override
  ConsumerState<NfcReadingScreen> createState() => _NfcReadingScreenState();
}

/// How long the done stage stays up after a successful read. Tests that do
/// not look at it set it to zero.
final nfcDoneHoldProvider = Provider<Duration>(
  (ref) => NfcDoneCheck.holdDuration,
);

/// What the screen shows while reading. Only states without an error or a
/// cancel have one; those keep their own layout.
enum _NfcStage { waiting, reading, done, nfcOff }

class _NfcReadingScreenState extends ConsumerState<NfcReadingScreen>
    with RouteAware, WidgetsBindingObserver {
  String? issuanceError;

  /// True when the current [issuanceError] is the issuer rejecting the face
  /// match (HTTP 400 during a face-verification issuance), so the error screen
  /// can show the dedicated failed-face illustration.
  bool _issuanceErrorIsFaceMatch = false;

  /// True once face verification is done and we are contacting the issuer.
  /// Shows a loader instead of the (already-completed) readout page, so the
  /// user is not sent back to the readout screen after the liveness session.
  bool _preparingIssuance = false;

  DocumentType get _documentType => switch (widget.mrz) {
    ScannedPassportMrz() => .passport,
    ScannedDrivingLicenceMrz() => .drivingLicence,
    ScannedIdCardMrz() => .identityCard,
  };

  // Android polls for the tag as soon as the screen opens. iOS needs a tap
  // first, because that opens Apple's own NFC sheet.
  bool get _listensAtOnce => defaultTargetPlatform == .android;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoStartScanning());
  }

  /// Starts the read without a tap on Android.
  void _autoStartScanning() {
    if (!_listensAtOnce || !mounted) return;
    if (_readDocumentReaderState() is! DocumentReaderPending) return;

    _startScanning();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == .resumed) _recheckNfc();
  }

  /// Back from the system settings: carry on once NFC is on. The reader keeps
  /// reporting NFC as unavailable until it is reset.
  Future<void> _recheckNfc() async {
    if (_readDocumentReaderState() is! DocumentReaderNfcUnavailable) return;

    final status = await ref
        .read(nfcStatusReaderProvider)()
        .catchError((_) => NfcStatus.notSupported);
    if (!mounted || status != NfcStatus.enabled) return;

    _getDocumentReader().reset();
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
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _startScanning() async {
    setState(() {
      issuanceError = null;
      _issuanceErrorIsFaceMatch = false;
      _preparingIssuance = false;
    });
    // Capture the root navigator context up front, outside the try. The Regula
    // liveness UI is a native screen that backgrounds — and on some devices
    // tears down — this widget, so we must not rely on this screen's own
    // context/mounted state to navigate to issuance afterwards, or issuance
    // never opens and the user is left on the successful-readout page. The
    // catch below needs it for the same reason, so it cannot live in the try.
    final navContext = Navigator.of(context, rootNavigator: true).context;
    // Set once the native liveness UI is in front. Only from that point can
    // something other than the user unmount this screen, so only from there is
    // a dead State a reason to route the error somewhere else. Everything
    // before it is ordinary Flutter code, where an unmounted State means the
    // user left this route themselves — pushing a full-screen error onto
    // wherever they went would be a surprise, so that case stays dropped.
    var livenessStarted = false;
    try {
      final passportIssuer = ref.read(passportIssuerProvider);

      final startValidation = await passportIssuer
          .startSessionAtPassportIssuer();
      if (!mounted) return;
      // Publish the issuer's announcement before resolving the face service:
      // the flavor builders construct against it (the native SDK targets the
      // announced Face API). The issuer decides whether face verification
      // applies to this session — the wallet never runs or skips the step on
      // its own — so a capable service without an announcement stays unused,
      // and old issuers that announce nothing simply skip the step.
      ref
          .read(faceVerificationConfigProvider.notifier)
          .set(startValidation.faceVerification);
      final faceService = startValidation.faceVerification == null
          ? null
          : ref.read(regulaFaceServiceProvider);

      // The iOS reader sheet resigns the app active for the whole read, which
      // would put the privacy-screen blur over the scanning animation and its
      // progress text. Hold it back until the sheet is gone.
      final result = await PrivacyScreen.suspendDuring(
        () => _getDocumentReader().readDocument(
          iosNfcMessages: _createStageNfcMessageMapper(),
          activeAuthenticationParams: startValidation.nonceAndSessionId,
        ),
      );

      if (result != null) {
        // G6: the check draws itself and stays a moment before the flow moves
        // on to the face check or issuance.
        if (mounted) {
          await Future<void>.delayed(ref.read(nfcDoneHoldProvider));
          if (!mounted) return;
        }

        final (pdr, rawDocData) = result;
        var toIssue = rawDocData;
        final faceVerification = faceService != null;
        // When face verification is enabled, show the Yivi intro after the
        // successful-readout page (Regula's own onboarding is skipped), then
        // run a Regula liveness session and attach its transaction id so the
        // issuer can match the live face against the document chip portrait.
        // Disabled (null service) skips straight to issuance.
        if (faceVerification) {
          if (!mounted) return;
          // Switch the screen behind the intro to a loader now, so the readout
          // page is not revealed again after the intro/liveness — instead the
          // user sees a loader that leads into issuance.
          setState(() => _preparingIssuance = true);
          final proceed =
              await (widget.faceIntro ?? FaceVerificationIntroScreen.show)(
                context,
              );
          if (!proceed) {
            if (mounted) {
              setState(() => _preparingIssuance = false);
              // The reader was dropped while the loader showed. The new one
              // starts in Pending, which ref.listen does not report.
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _autoStartScanning(),
              );
            }
            return;
          }
          if (!mounted) return;
          final languageCode = FlutterI18n.currentLocale(context)?.languageCode;
          livenessStarted = true;
          toIssue = await withLivenessTransaction(
            faceService,
            rawDocData,
            languageCode: languageCode,
          );
        }
        // navContext is the root navigator's context (guaranteed to outlive
        // this screen); _startIssuance re-checks navContext.mounted before use.
        // For the face flow, replace this readout route so issuance does not
        // return here afterwards. A rejected face match surfaces as an issuance
        // error and is shown on the generic error screen (with retry/cancel),
        // where retry re-runs the readout and liveness.
        await _startIssuance(
          toIssue,
          passportIssuer,
          // ignore: use_build_context_synchronously
          navContext,
          pushReplacement: faceVerification,
          faceVerification: faceVerification,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          issuanceError = e.toString();
        });
      } else if (livenessStarted && navContext.mounted) {
        // The liveness UI tore this screen down, so there is no State left to
        // render the in-screen error on. Surface the failure through the root
        // navigator instead, so a failed liveness session is not silently
        // swallowed. Replace the readout route rather than pushing over it,
        // exactly as _startIssuance does for this same flow, so dismissing the
        // error does not land the user back on the readout page they already
        // finished.
        navContext.pushReplacementErrorScreen(message: e.toString());
      }
    }
  }

  Future<void> _startIssuance(
    RawDocumentData result,
    PassportIssuer passportIssuer,
    BuildContext navContext, {
    bool pushReplacement = false,
    bool faceVerification = false,
  }) async {
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
      if (!navContext.mounted) {
        return;
      }

      // Handle it like any other external issuance session, navigating through
      // the root navigator so issuance opens even if this NFC screen was torn
      // down while the native liveness UI was in front. For the face flow we
      // replace this route so the user does not return to the readout page.
      await handlePointer(
        navContext,
        SessionPointer(
          protocol: .irma,
          u: sessionPtr.u,
          irmaqr: sessionPtr.irmaqr,
          continueOnSecondDevice: true,
        ),
        pushReplacement: pushReplacement,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("issuance error: $e");
      }
      if (mounted) {
        setState(() {
          issuanceError = e.toString();
          // A rejected face match surfaces as an HTTP 400 from the issuer
          // (vcmrtd: `Exception('Store failed: 400 …')`); flag it so the error
          // screen shows the dedicated failed-face illustration.
          _issuanceErrorIsFaceMatch =
              faceVerification && e.toString().contains("Store failed: 400");
          _preparingIssuance = false;
        });
      } else if (navContext.mounted) {
        // The native liveness UI tore this screen down, so there is no State
        // left to render the in-screen error on (its `_preparingIssuance`
        // loader is gone with it). Surface the failure through the root
        // navigator instead, mirroring the success path and handlePointer, so
        // it is not silently swallowed.
        if (pushReplacement) {
          navContext.pushReplacementErrorScreen(message: e.toString());
        } else {
          navContext.pushErrorScreen(message: e.toString());
        }
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
        illustrationAsset: _issuanceErrorIsFaceMatch
            ? "error/failed_face_verification.svg"
            : "error/general_error_illustration.svg",
      );
    }

    // After face verification we contact the issuer; show a loader that leads
    // into issuance rather than falling back to the completed readout page.
    if (_preparingIssuance) {
      return _buildPreparing(context);
    }

    final passportState = _watchDocumentReaderState();

    ref.listen(_readerStateProvider, (previous, next) {
      if (next is DocumentReaderPending && previous is! DocumentReaderPending) {
        _autoStartScanning();
      }
    });

    final stage = _stageFor(passportState);
    if (stage != null) {
      return _buildStage(context, stage, passportState);
    }

    final uiState = passportReadingStateToUiState(passportState);

    if (passportState case DocumentReaderFailed(
      :final logs,
      :final sensitiveLogs,
    )) {
      return _buildError(context, uiState, logs, sensitiveLogs: sensitiveLogs);
    }

    // Cancelled, or still cancelling.
    return _buildCancelled(context, uiState);
  }

  _NfcStage? _stageFor(DocumentReaderState state) => switch (state) {
    DocumentReaderNfcUnavailable() => _NfcStage.nfcOff,
    // Connecting is the wait for the tag, so the phone has not touched the
    // document yet.
    DocumentReaderPending() || DocumentReaderConnecting() => _NfcStage.waiting,
    DocumentReaderAuthenticating() ||
    DocumentReaderReadingCardAccess() ||
    DocumentReaderReadingCOM() ||
    DocumentReaderReadingDataGroup() ||
    DocumentReaderReadingSOD() ||
    DocumentReaderActiveAuthentication() => _NfcStage.reading,
    DocumentReaderSuccess() => _NfcStage.done,
    _ => null,
  };

  Widget _buildStage(
    BuildContext context,
    _NfcStage stage,
    DocumentReaderState state,
  ) {
    // In a sheet its close button is the way out: no Cancel here.
    final inSheet = DocumentStepInSheet.of(context);
    final cancelAction = NfcStageAction.secondary(
      labelKey: "document_flow.cancel",
      onPressed: cancel,
    );
    const keys = "document_flow.nfc";

    final (picture, text, actions) = switch (stage) {
      _NfcStage.waiting => (
        _waitingPicture(context),
        (
          "$keys.waiting_title",
          _documentType == .passport
              ? "$keys.waiting_body_passport"
              : "$keys.waiting_body_card",
        ),
        [
          if (state is DocumentReaderPending && !_listensAtOnce)
            NfcStageAction.primary(
              labelKey: "document_flow.start",
              onPressed: _startScanning,
            )
          else if (!inSheet)
            cancelAction,
        ],
      ),
      _NfcStage.reading => (
        NfcProgressRing(
          progress: progressForState(state),
          label: FlutterI18n.translate(context, _documentType.readingLabelKey),
        ),
        ("$keys.reading_title", "$keys.reading_body"),
        [if (!inSheet) cancelAction],
      ),
      _NfcStage.done => (
        const NfcDoneCheck(),
        ("$keys.done_title", "$keys.done_body"),
        <NfcStageAction>[],
      ),
      _NfcStage.nfcOff => (
        const NfcOffIllustration(),
        ("$keys.off_title", "$keys.off_body"),
        [
          if (defaultTargetPlatform == .android)
            NfcStageAction.primary(
              labelKey: "$keys.open_settings",
              onPressed: () => ref.read(nfcSettingsOpenerProvider).open(),
            ),
          if (!inSheet) cancelAction,
        ],
      ),
    };

    return NfcStageScaffold(
      appBarTitleKey: widget.translationKeys.title,
      picture: picture,
      // Nothing to go back to once the read is done.
      leading: stage == _NfcStage.done ? null : const YiviBackButton(),
      titleKey: text.$1,
      bodyKey: text.$2,
      textParams: {
        "document": FlutterI18n.translate(context, _documentType.nameKey),
      },
      actions: actions,
    );
  }

  /// The phone settling on the passport cover, or on the back of the card,
  /// as on the canvas.
  Widget _waitingPicture(BuildContext context) {
    final isPassport = _documentType == .passport;
    return Semantics(
      image: true,
      label: isPassport
          ? FlutterI18n.translate(
              context,
              "document_flow.nfc.waiting_image_alt",
            )
          : FlutterI18n.translate(
              context,
              "document_flow.nfc.waiting_image_alt_card",
              translationParams: {
                "document": FlutterI18n.translate(
                  context,
                  _documentType.nameKey,
                ),
              },
            ),
      child: NfcPhoneOnDocument(
        document: switch (_documentType) {
          .passport => NfcDocumentPicture.passport,
          .identityCard => NfcDocumentPicture.identityCard,
          .drivingLicence => NfcDocumentPicture.drivingLicence,
        },
      ),
    );
  }

  /// "One moment, preparing your data…" under a spinner, centred, as on
  /// the canvas.
  Widget _buildPreparing(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: DocumentStepInSheet.of(context)
          ? Colors.transparent
          : palette.background,
      // In a sheet its bar has the title.
      appBar: DocumentStepInSheet.of(context)
          ? null
          : IrmaAppBar(titleTranslationKey: "face_verification.title"),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: .min,
              spacing: 20,
              children: [
                SizedBox.square(
                  dimension: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: palette.primary,
                    backgroundColor: palette.outline,
                  ),
                ),
                TranslatedText(
                  "face_verification.preparing",
                  textAlign: .center,
                  style: palette
                      .body(17)
                      .copyWith(height: 26 / 17, color: palette.heading),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    _UiState uiState,
    String logs, {
    String? sensitiveLogs,
    String illustrationAsset = "error/general_error_illustration.svg",
  }) {
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
            style: theme.bodyHeading,
          ),
          SizedBox(height: theme.defaultSpacing),
          _OrientationAwareTranslatedText(uiState.tipKey),
          SizedBox(height: theme.defaultSpacing),
          GestureDetector(
            onTap: () {
              _showLogsDialog(
                context,
                logs: logs,
                sensitiveLogs: sensitiveLogs,
              );
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
        child: SvgPicture.asset(yiviAsset(illustrationAsset)),
      ),
      // In a sheet, the sheet's own buttons; its close button is the way out.
      bottomNavigationBar: DocumentStepInSheet.of(context)
          ? DocumentFlowFooter(
              buttons: [
                DocumentFlowButton(
                  key: DocumentFlowButton.primaryKey,
                  labelKey: "ui.retry",
                  onPressed: retry,
                ),
              ],
            )
          : IrmaBottomBar(
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
      // In a sheet, the sheet's own buttons; its close button is the way out.
      bottomNavigationBar: DocumentStepInSheet.of(context)
          ? DocumentFlowFooter(
              buttons: [
                DocumentFlowButton(
                  key: DocumentFlowButton.primaryKey,
                  labelKey: "ui.retry",
                  onPressed: retry,
                ),
              ],
            )
          : IrmaBottomBar(
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

  ProviderListenable<DocumentReaderState> get _readerStateProvider =>
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
      };

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
    final reader = ref.read(
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
    return reader;
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

  /// The text on Apple's NFC sheet, in step with the on-screen stage, e.g.
  /// "Niet bewegen · 62%" while reading.
  IosNfcMessageMapper _createStageNfcMessageMapper() {
    const keys = "document_flow.nfc";

    return (state) {
      final params = {
        "document": FlutterI18n.translate(context, _documentType.nameKey),
      };
      String translate(String key) =>
          FlutterI18n.translate(context, key, translationParams: params);

      return switch (_stageFor(state)) {
        _NfcStage.waiting => translate("$keys.waiting_title"),
        _NfcStage.reading =>
          "${translate("$keys.reading_title")} · "
              "${(progressForState(state) * 100).round()}%",
        _NfcStage.done => translate("$keys.done_title"),
        _ => FlutterI18n.translate(context, _getTranslationKeyForState(state)),
      };
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

Future _showLogsDialog(
  BuildContext context, {
  required String logs,
  String? sensitiveLogs,
}) async {
  return showDialog(
    context: context,
    builder: (context) {
      return NfcErrorDialog(logs: logs, sensitiveLogs: sensitiveLogs);
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
        _OrientationAwareTranslatedText(titleKey, style: theme.bodyHeading),
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
    // In a sheet held sideways: what went wrong and the button at the left,
    // the illustration on a card at the right.
    final footer = bottomNavigationBar;
    if (documentStepSplit(context)) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SheetSplit(
          endFills: true,
          start: [instruction],
          end: SheetPictureCard(
            child: SizedBox(width: 280, height: 240, child: illustration),
          ),
          actions: footer is DocumentFlowFooter
              ? DocumentFlowFooter.sheetActions(context, footer.buttons)
              : null,
        ),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      // The redesign's page background (backgroundTertiary is the same
      // colour); in a sheet its glass, under the sheet's own bar.
      backgroundColor: DocumentStepInSheet.of(context)
          ? Colors.transparent
          : theme.backgroundTertiary,
      appBar: DocumentStepInSheet.of(context)
          ? null
          : IrmaAppBar(titleTranslationKey: titleTranslationKey),
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
