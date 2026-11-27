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
import "../../../util/handle_pointer.dart";
import "../../../util/navigation.dart";
import "../../../util/privacy_screen.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_confirmation_dialog.dart";
import "../../../widgets/translated_text.dart";
import "document_translation_keys.dart";
import "face_verification_intro_screen.dart";
import "widgets/driving_licence_nfc_scanning_animation.dart";
import "widgets/id_card_nfc_scanning_animation.dart";
import "widgets/nfc_error_dialog.dart";
import "widgets/nfc_stage_pictures.dart";
import "widgets/nfc_stage_view.dart";

/// The document specific texts of the NFC screen: the app bar title, the
/// cancel dialog and the texts of a read that failed or was cancelled. The
/// stages of a read that goes well share their texts (`document_flow.nfc.*`).
class NfcReadingTranslationKeys {
  final String cancelDialogTitle;
  final String cancelDialogExplanation;
  final String cancelDialogDecline;
  final String cancelDialogConfirm;
  final String error;
  final String errorGeneric;
  final String title;
  final String cancelledByUser;
  final String cancelled;
  final String cancelling;
  final String failedToInitiateSession;

  /// Shown when the chip turns out to be the other card in ID-card format: a
  /// residence permit read as an ID card, or the other way round. Only the ID
  /// card and residence permit flows need them.
  final String? wrongDocument;
  final String? wrongDocumentTip;

  NfcReadingTranslationKeys({
    required this.cancelDialogTitle,
    required this.cancelDialogExplanation,
    required this.cancelDialogDecline,
    required this.cancelDialogConfirm,
    required this.error,
    required this.errorGeneric,
    required this.title,
    required this.cancelledByUser,
    required this.cancelled,
    required this.cancelling,
    required this.failedToInitiateSession,
    this.wrongDocument,
    this.wrongDocumentTip,
  });
}

/// The card [document] turns out to be when it is not the [picked] one: a
/// residence permit read in the ID card flow, or the other way round. This
/// mirrors the passport issuer, which issues an ID card only to a national of
/// the issuing state and a residence permit only to someone who is not. Null
/// when the document matches, and for passports and driving licences.
@visibleForTesting
DocumentType? wrongDocumentType(DocumentData document, DocumentType picked) {
  if (document is! PassportData) return null;
  final national = document.mrz.nationality == document.mrz.country;
  return switch (picked) {
    .identityCard when !national => .residencePermit,
    .residencePermit when national => .identityCard,
    _ => null,
  };
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

/// How long the done stage stays up after a successful read. Tests that do not
/// look at it set it to zero.
final nfcDoneHoldProvider = Provider<Duration>(
  (ref) => NfcDoneCheck.holdDuration,
);

/// What the screen shows while nothing went wrong. A failed or cancelled read
/// has its own layout, with a retry.
enum _NfcStage { waiting, reading, reconnecting, done, nfcOff }

const _stageKeys = "document_flow.nfc";

/// Asks the user to put the phone back on the document, both while the reader
/// retries a lost connection and when it gave up.
const _repositionTipKey = "$_stageKeys.reposition_tip";

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

  /// Set when the chip turned out to be the other card than the one picked;
  /// the read is then not sent to the issuer, so it can never be issued as
  /// the wrong credential.
  DocumentType? _wrongDocument;

  /// The read failed while the reader was retrying a lost connection. vcmrtd
  /// reports such a failure as [DocumentReadingError.unknown], so this is how
  /// the screen knows the user should put the phone back.
  bool _failedAfterConnectionLoss = false;

  /// The progress of the last state vcmrtd could place, kept for a state it
  /// cannot (one a later vcmrtd adds), so the ring does not jump.
  double _lastProgress = 0;

  DocumentType get _documentType => widget.mrz.documentType;

  // Android polls for the tag as soon as the screen opens. iOS needs a tap
  // first, because that opens Apple's own NFC sheet.
  bool get _listensAtOnce => defaultTargetPlatform == .android;

  /// The picture of the card documents while the phone is not on them yet.
  /// The passport has its own drawing, see [_waitingPicture].
  Widget _cardAnimation() {
    return switch (widget.mrz) {
      ScannedDrivingLicenceMrz() => DrivingLicenceNfcScanningAnimation(),
      _ => IdCardNfcScanningAnimation(),
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoStartScanning());
  }

  /// Starts the read without a tap, on Android.
  void _autoStartScanning() {
    if (!mounted || !_listensAtOnce) return;
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
    if (!mounted) return;
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
      _wrongDocument = null;
      _failedAfterConnectionLoss = false;
      _lastProgress = 0;
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
      // would put the privacy-screen blur over the stage and its text. Hold it
      // back until the sheet is gone.
      final result = await PrivacyScreen.suspendDuring(
        () => _getDocumentReader().readDocument(
          iosNfcMessages: _createIosNfcMessageMapper(),
          activeAuthenticationParams: startValidation.nonceAndSessionId,
        ),
      );

      if (result != null) {
        final (pdr, rawDocData) = result;
        final wrongDocument = wrongDocumentType(pdr, widget.mrz.documentType);
        if (wrongDocument != null) {
          if (mounted) setState(() => _wrongDocument = wrongDocument);
          return;
        }

        // The check draws itself and stays a moment before the flow moves on
        // to the face check or issuance.
        await Future<void>.delayed(ref.read(nfcDoneHoldProvider));
        if (!mounted) return;

        var toIssue = rawDocData;
        final faceVerification = faceService != null;
        // When face verification is enabled, show the Yivi intro after the
        // successful-readout page (Regula's own onboarding is skipped), then
        // run a Regula liveness session and attach its transaction id so the
        // issuer can match the live face against the document chip portrait.
        // Disabled (null service) skips straight to issuance.
        if (faceVerification) {
          // Switch the screen behind the intro to a loader now, so the readout
          // page is not revealed again after the intro/liveness — instead the
          // user sees a loader that leads into issuance.
          setState(() => _preparingIssuance = true);
          final proceed = await FaceVerificationIntroScreen.show(context);
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
        widget.mrz.documentType,
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
              faceVerification &&
              e.toString().contains("Store failed: 400") &&
              !e.toString().contains("error:wrong-document-type");
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
        titleKey: widget.translationKeys.error,
        tipKey: widget.translationKeys.errorGeneric,
        logs: issuanceError!,
        illustrationAsset: _issuanceErrorIsFaceMatch
            ? "error/failed_face_verification.svg"
            : "error/general_error_illustration.svg",
      );
    }

    if (_wrongDocument case final wrongDocument?) {
      return _buildError(
        context,
        titleKey:
            widget.translationKeys.wrongDocument ??
            widget.translationKeys.error,
        tipKey:
            widget.translationKeys.wrongDocumentTip ??
            widget.translationKeys.errorGeneric,
        logs:
            "Picked ${widget.mrz.documentType.name}, "
            "but the chip shows a ${wrongDocument.name}.",
      );
    }

    // After face verification we contact the issuer; show a loader that leads
    // into issuance rather than falling back to the completed readout page.
    if (_preparingIssuance) {
      return _buildPreparing(context);
    }

    final readerState = _watchDocumentReaderState();

    ref.listen(_readerStateProvider, (previous, next) {
      if (next is DocumentReaderFailed) {
        _failedAfterConnectionLoss = previous is DocumentReaderReconnecting;
      }
      if (next is DocumentReaderPending && previous is! DocumentReaderPending) {
        _autoStartScanning();
      }
    });

    if (_stageFor(readerState) case final stage?) {
      return _buildStage(context, stage, readerState);
    }

    if (readerState case DocumentReaderFailed(
      :final error,
      :final logs,
      :final sensitiveLogs,
    )) {
      final (tipKey, tipParams) = _failureTip(error);
      return _buildError(
        context,
        titleKey: widget.translationKeys.error,
        tipKey: tipKey,
        tipParams: tipParams,
        logs: logs,
        sensitiveLogs: sensitiveLogs,
      );
    }

    return _buildCancelled(
      context,
      titleKey: readerState is DocumentReaderCancelling
          ? widget.translationKeys.cancelling
          : widget.translationKeys.cancelled,
    );
  }

  /// The stage for [state], or null for a failed or cancelled read. Every
  /// state that is neither is a read in progress, including one a later vcmrtd
  /// adds: it shows the reading stage rather than an error.
  _NfcStage? _stageFor(DocumentReaderState state) => switch (state) {
    DocumentReaderNfcUnavailable() => .nfcOff,
    // Connecting is the wait for the tag, so the phone has not touched the
    // document yet.
    DocumentReaderPending() || DocumentReaderConnecting() => .waiting,
    // The connection dropped and the reader retries. The screen stays at the
    // step it was on: before contact that is still the wait for the tag, after
    // it the ring keeps its progress and the text asks for the phone to go
    // back.
    DocumentReaderReconnecting(:final previousState) =>
      _stageFor(previousState) == .waiting ? .waiting : .reconnecting,
    DocumentReaderSuccess() => .done,
    DocumentReaderFailed() ||
    DocumentReaderCancelling() ||
    DocumentReaderCancelled() => null,
    _ => .reading,
  };

  /// vcmrtd's progress for [state]; for a reconnect, that of the step it
  /// retries. vcmrtd throws for a state it does not know, which then keeps the
  /// last progress.
  double _progressFor(DocumentReaderState state) {
    try {
      return _lastProgress = progressForState(state);
    } on Exception {
      return _lastProgress;
    }
  }

  /// Fills the `{document}` placeholder of the shared stage texts.
  Map<String, String> _documentParams(BuildContext context) => {
    "document": FlutterI18n.translate(context, _documentType.nameKey),
  };

  /// The hint under a failed read. A lost connection gets the same request to
  /// put the phone back as the reconnecting stage.
  (String, Map<String, String>) _failureTip(DocumentReadingError error) {
    final reposition = (_repositionTipKey, _documentParams(context));
    return switch (error) {
      .tagLost || .timeoutWaitingForTag => reposition,
      .unknown when _failedAfterConnectionLoss => reposition,
      .unknown => (widget.translationKeys.errorGeneric, const {}),
      .failedToInitiateSession => (
        widget.translationKeys.failedToInitiateSession,
        const {},
      ),
      .invalidatedByUser => ("", const {}),
    };
  }

  Widget _buildStage(
    BuildContext context,
    _NfcStage stage,
    DocumentReaderState state,
  ) {
    final cancelAction = NfcStageAction.secondary(
      labelKey: "document_flow.cancel",
      onPressed: cancel,
    );
    NfcProgressRing ring() => NfcProgressRing(
      progress: _progressFor(state),
      label: FlutterI18n.translate(context, _documentType.readingLabelKey),
    );

    final (picture, titleKey, bodyKey, actions) = switch (stage) {
      .waiting => (
        _waitingPicture(context),
        "$_stageKeys.waiting_title",
        _documentType == .passport
            ? "$_stageKeys.waiting_body_passport"
            : "$_stageKeys.waiting_body_card",
        [
          if (state is DocumentReaderPending && !_listensAtOnce)
            NfcStageAction.primary(
              labelKey: "document_flow.start",
              onPressed: _startScanning,
            )
          else
            cancelAction,
        ],
      ),
      .reading => (
        ring(),
        "$_stageKeys.reading_title",
        "$_stageKeys.reading_body",
        [cancelAction],
      ),
      .reconnecting => (
        ring(),
        "$_stageKeys.reconnecting_title",
        _repositionTipKey,
        [cancelAction],
      ),
      .done => (
        const NfcDoneCheck(),
        "$_stageKeys.done_title",
        "$_stageKeys.done_body",
        <NfcStageAction>[],
      ),
      .nfcOff => (
        const NfcOffIllustration(),
        "$_stageKeys.off_title",
        "$_stageKeys.off_body",
        [
          if (defaultTargetPlatform == .android)
            NfcStageAction.primary(
              labelKey: "$_stageKeys.open_settings",
              onPressed: () => ref.read(nfcSettingsOpenerProvider).open(),
            ),
          cancelAction,
        ],
      ),
    };

    return NfcStageScaffold(
      appBarTitleKey: widget.translationKeys.title,
      picture: picture,
      // Nothing to go back to once the read is done.
      leading: stage == .done ? null : const YiviBackButton(),
      titleKey: titleKey,
      bodyKey: bodyKey,
      textParams: _documentParams(context),
      actions: actions,
    );
  }

  Widget _waitingPicture(BuildContext context) {
    if (_documentType != .passport) {
      return SizedBox.square(dimension: 300, child: _cardAnimation());
    }
    return Semantics(
      image: true,
      label: FlutterI18n.translate(context, "$_stageKeys.waiting_image_alt"),
      child: const NfcPhoneOnPassport(),
    );
  }

  Widget _buildPreparing(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: IrmaAppBar(titleTranslationKey: "face_verification.title"),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: .min,
            children: [
              CircularProgressIndicator(color: theme.primary),
              SizedBox(height: theme.largeSpacing),
              Padding(
                padding: .symmetric(horizontal: theme.largeSpacing),
                child: TranslatedText(
                  "face_verification.preparing",
                  textAlign: .center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context, {
    required String titleKey,
    required String tipKey,
    Map<String, String> tipParams = const {},
    required String logs,
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
          _OrientationAwareTranslatedText(titleKey, style: theme.bodyHeading),
          SizedBox(height: theme.defaultSpacing),
          _OrientationAwareTranslatedText(tipKey, translationParams: tipParams),
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
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "ui.retry",
        onPrimaryPressed: retry,
        secondaryButtonLabel: "ui.cancel",
        onSecondaryPressed: cancel,
      ),
    );
  }

  Widget _buildCancelled(BuildContext context, {required String titleKey}) {
    final theme = IrmaTheme.of(context);
    return _NfcScaffold(
      titleTranslationKey: widget.translationKeys.title,
      instruction: _TitleAndBody(
        titleKey: titleKey,
        bodyKey: widget.translationKeys.cancelledByUser,
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

  DocumentReaderState _readDocumentReaderState() =>
      ref.read(_readerStateProvider);

  DocumentReaderState _watchDocumentReaderState() =>
      ref.watch(_readerStateProvider);

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

  /// The text on Apple's NFC sheet, in step with the on-screen stage, e.g.
  /// "Niet bewegen · 62%" while reading.
  IosNfcMessageMapper _createIosNfcMessageMapper() {
    return (state) {
      // vcmrtd calls this during the read, which can outlive the screen.
      if (!mounted) return "";

      String translate(String key) => FlutterI18n.translate(
        context,
        key,
        translationParams: _documentParams(context),
      );

      return switch (_stageFor(state)) {
        .waiting => translate("$_stageKeys.waiting_title"),
        .reading =>
          "${translate("$_stageKeys.reading_title")} · "
              "${(_progressFor(state) * 100).round()}%",
        .reconnecting =>
          "${translate("$_stageKeys.reconnecting_title")}\n"
              "${translate(_repositionTipKey)}",
        .done => translate("$_stageKeys.done_title"),
        .nfcOff => translate("$_stageKeys.off_title"),
        null => translate(switch (state) {
          DocumentReaderCancelling() => widget.translationKeys.cancelling,
          DocumentReaderCancelled() => widget.translationKeys.cancelled,
          _ => widget.translationKeys.error,
        }),
      };
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

/// The layout of a failed or cancelled read: an illustration, the text and a
/// bar with retry and cancel.
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
  const _OrientationAwareTranslatedText(
    this.translationKey, {
    this.style,
    this.translationParams = const {},
  });

  final String translationKey;
  final TextStyle? style;
  final Map<String, String> translationParams;

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
        translationParams: translationParams,
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
