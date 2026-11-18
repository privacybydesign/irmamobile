import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../../package_name.dart";
import "../../../../yivi_core.dart";
import "../../../providers/nfc_availability_provider.dart";
import "../../../providers/nfc_settings_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/after_frame.dart";
import "../../../util/i18n.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/feedback/done_check.dart";
import "../../../widgets/feedback/yivi_spinner.dart";
import "../../../widgets/text/translated_text.dart";
import "document_flow.dart";
import "document_issuance.dart";
import "document_step_in_sheet.dart";
import "document_translation_keys.dart";
import "widgets/nfc_error_dialog.dart";
import "widgets/nfc_stage_pictures.dart";
import "widgets/nfc_stage_view.dart";

class NfcReadingScreen extends ConsumerStatefulWidget {
  final ScannedMrz mrz;

  /// Which read of [mrz] this is: reading again starts a new one.
  final int attempt;

  const NfcReadingScreen({required this.mrz, this.attempt = 0, super.key});

  @override
  ConsumerState<NfcReadingScreen> createState() => _NfcReadingScreenState();
}

/// The error pictures' size in the stage's picture area.
const _errorPictureSize = 240.0;

/// What the screen shows while reading. Only states without an error or a
/// cancel have one; those keep their own layout.
enum _NfcStage { waiting, reading, done, nfcOff }

/// The chip page: the reader's stages, and what [DocumentIssuance] says once
/// the chip is read. It starts the read (on Android at once, on iOS on
/// Start, which opens Apple's NFC sheet) and carries on when NFC is
/// switched on in the settings.
class _NfcReadingScreenState extends ConsumerState<NfcReadingScreen>
    with WidgetsBindingObserver {
  // Android polls for the tag as soon as the screen opens. iOS needs a tap
  // first, because that opens Apple's own NFC sheet.
  bool get _listensAtOnce => defaultTargetPlatform == .android;

  ChipRead get _read => (mrz: widget.mrz, attempt: widget.attempt);

  NotifierProvider<DocumentIssuance, DocumentIssuanceState> get _issuance =>
      documentIssuanceProvider(_read);

  /// The reader of [NfcReadingScreen.mrz]'s document.
  NotifierProvider<DocumentReader, DocumentReaderState> get _reader =>
      documentReaderOf(widget.mrz);

  /// A text of this document's chip screen: `{document}.nfc.[part]`.
  String _k(String part) => widget.mrz.documentType.nfcKey(part);

  /// Shown when the chip turns out to be the other card in ID-card format: a
  /// residence permit read as an ID card, or the other way round. Only the ID
  /// card and residence permit flows have them.
  bool get _hasWrongDocumentTexts => widget.mrz is ScannedIdCardMrz;

  /// The document's name, for the `{document}` placeholder.
  String _documentName(BuildContext context) =>
      context.tr(widget.mrz.documentType.nameKey);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    afterFrame(_autoStartScanning);
  }

  /// Starts the read without a tap on Android.
  void _autoStartScanning() {
    if (!_listensAtOnce || !mounted) return;
    if (ref.read(_issuance) is! IssuanceIdle) return;
    if (ref.read(_reader) is! DocumentReaderPending) return;

    _startScanning();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == .resumed) _recheckNfc();
  }

  /// Back from the system settings: carry on once NFC is on. The reader keeps
  /// reporting NFC as unavailable until it is reset.
  Future<void> _recheckNfc() async {
    if (ref.read(_reader) is! DocumentReaderNfcUnavailable) return;

    final status = await ref
        .read(nfcStatusReaderProvider)()
        .catchError((_) => NfcStatus.notSupported);
    if (!mounted || status != NfcStatus.enabled) return;

    ref.read(_reader.notifier).reset();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startScanning() {
    ref
        .read(_issuance.notifier)
        .start(
          messages: _createStageNfcMessageMapper(),
          language: FlutterI18n.currentLocale(context)?.languageCode,
          // The liveness screen can tear this page down; the root outlives it.
          root: Navigator.of(context, rootNavigator: true).context,
        );
  }

  void _retry() {
    ref.read(_issuance.notifier).cancel();
    _startScanning();
  }

  @override
  Widget build(BuildContext context) {
    final issuance = ref.watch(_issuance);
    // Not now on the face check: the reader was dropped while the loader
    // showed, and the new one starts in Pending, which the listen on the
    // reader does not report.
    ref.listen(_issuance, (previous, next) {
      if (previous is IssuancePreparing && next is IssuanceIdle) {
        afterFrame(_autoStartScanning);
      }
    });

    // In a sheet its bar says the data is being fetched while the loader
    // shows: once the face check over it is gone (the loader is switched on
    // under it). After the build: it rebuilds the sheet's bar.
    final flowProvider = documentFlowProvider(widget.mrz.documentType);
    final flow = ref.exists(flowProvider)
        ? ref.read(flowProvider.notifier)
        : null;
    final shown =
        issuance is IssuancePreparing &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (flow != null) {
      // Still here then, so the sheet step around it is too.
      afterFrame(() => flow.preparing(shown));
    }

    switch (issuance) {
      // After the face check the issuer is called; a loader leads into
      // adding it rather than the finished read.
      case IssuancePreparing():
        return _buildPreparing(context);
      case IssuanceError(error: final WrongDocument error):
        return _buildError(
          context,
          _UiState(
            stateKey: _k(_hasWrongDocumentTexts ? "wrong_document" : "error"),
            tipKey: _k(
              _hasWrongDocumentTexts ? "wrong_document_tip" : "error_generic",
            ),
          ),
          error.details,
        );
      case IssuanceError(:final error):
        return _buildError(
          context,
          _UiState(stateKey: _k("error"), tipKey: _k("error_generic")),
          error.details,
          illustrationAsset: error is FaceRejected
              ? "error/failed_face_verification.svg"
              : "error/general_error_illustration.svg",
        );
      case IssuanceIdle():
        break;
    }

    final passportState = ref.watch(_reader);

    ref.listen(_reader, (previous, next) {
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
    return _buildError(context, uiState, null);
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
    const keys = "document_flow.nfc";
    // On a tablet (an Android one: an iPad has no NFC) it says tablet.
    final device = useFormSheet(context) ? "_tablet" : "";

    final (picture, text, actions) = switch (stage) {
      _NfcStage.waiting => (
        _waitingPicture(context),
        (
          "$keys.waiting_title$device",
          widget.mrz.documentType == .passport
              ? "$keys.waiting_body_passport"
              : "$keys.waiting_body_card$device",
        ),
        [
          if (state is DocumentReaderPending && !_listensAtOnce)
            NfcStageAction.primary(
              labelKey: "document_flow.start",
              onPressed: _startScanning,
            ),
        ],
      ),
      _NfcStage.reading => (
        NfcProgressRing(
          progress: progressForState(state),
          label: context.tr(widget.mrz.documentType.readingLabelKey),
        ),
        ("$keys.reading_title", "$keys.reading_body"),
        <NfcStageAction>[],
      ),
      _NfcStage.done => (
        const DoneCheck(),
        ("$keys.done_title", "$keys.done_body$device"),
        <NfcStageAction>[],
      ),
      _NfcStage.nfcOff => (
        const NfcOffIllustration(),
        ("$keys.off_title", "$keys.off_body$device"),
        [
          if (defaultTargetPlatform == .android)
            NfcStageAction.primary(
              labelKey: "$keys.open_settings",
              onPressed: () => ref.read(nfcSettingsOpenerProvider).open(),
            ),
        ],
      ),
    };

    return NfcStageScaffold(
      picture: picture,
      titleKey: text.$1,
      bodyKey: text.$2,
      textParams: {"document": _documentName(context)},
      actions: actions,
    );
  }

  /// The phone settling on the passport cover, or on the back of the card,
  /// as on the canvas.
  Widget _waitingPicture(BuildContext context) {
    final isPassport = widget.mrz.documentType == .passport;
    return Semantics(
      image: true,
      label: isPassport
          ? context.tr("document_flow.nfc.waiting_image_alt")
          : context.tr("document_flow.nfc.waiting_image_alt_card", {
              "document": _documentName(context),
            }),
      child: NfcPhoneOnDocument(
        document: NfcDocumentPicture.of(widget.mrz.documentType),
      ),
    );
  }

  /// "One moment, preparing your data…" under a spinner, centred, as on
  /// the canvas.
  Widget _buildPreparing(BuildContext context) {
    final palette = YiviPalette.of(context);
    // The sheet's bar has the title.
    return DocumentStepScaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x48),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: .min,
              spacing: YiviSpace.x24,
              children: [
                YiviSpinner(size: 44, color: palette.primary, track: true),
                TranslatedText(
                  "face_verification.preparing",
                  textAlign: .center,
                  style: palette
                      .body(16)
                      .copyWith(height: 24 / 16, color: palette.heading),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The failed or cancelled read, or adding it failed: a stage with the
  /// error's picture and "Try again". With [logs] (a failure), a link under
  /// the text shows them.
  Widget _buildError(
    BuildContext context,
    _UiState uiState,
    String? logs, {
    String? sensitiveLogs,
    String illustrationAsset = "error/general_error_illustration.svg",
  }) {
    return NfcStageScaffold(
      picture: SvgPicture.asset(
        yiviAsset(illustrationAsset),
        width: _errorPictureSize,
        height: _errorPictureSize,
      ),
      titleKey: uiState.stateKey,
      bodyKey: uiState.tipKey,
      textParams: {"document": _documentName(context)},
      actions: [
        NfcStageAction.primary(labelKey: "ui.retry", onPressed: _retry),
      ],
      below: logs == null
          ? null
          : TextLink(
              label: context.tr("error.button_show_error"),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    NfcErrorDialog(logs: logs, sensitiveLogs: sensitiveLogs),
              ),
            ),
    );
  }

  _UiState passportReadingStateToUiState(DocumentReaderState state) {
    final stateKey = _getTranslationKeyForState(state);
    final tipKey = _getTipKeyForState(state);

    return _UiState(tipKey: tipKey, stateKey: stateKey);
  }

  String _getTipKeyForState(DocumentReaderState state) {
    // The states with a stage of their own (see [_stageFor]) never get here.
    return switch (state) {
      DocumentReaderFailed(:final error) => _readingErrorToHintKey(error),
      DocumentReaderCancelling() => _k("cancelled_by_user"),
      DocumentReaderCancelled() => _k("cancelled_by_user"),
      _ => throw Exception("unexpected state: $state"),
    };
  }

  String _getTranslationKeyForState(DocumentReaderState state) {
    // The states with a stage of their own (see [_stageFor]) never get here.
    return switch (state) {
      DocumentReaderCancelled() => _k("cancelled"),
      DocumentReaderCancelling() => _k("cancelled_by_user"),
      DocumentReaderFailed() => _k("error"),
      _ => "",
    };
  }

  /// The text on Apple's NFC sheet, in step with the on-screen stage, e.g.
  /// "Don't move · 62%" while reading.
  IosNfcMessageMapper _createStageNfcMessageMapper() {
    const keys = "document_flow.nfc";

    return (state) {
      final params = {"document": _documentName(context)};
      String translate(String key) => context.tr(key, params);

      return switch (_stageFor(state)) {
        _NfcStage.waiting => translate("$keys.waiting_title"),
        _NfcStage.reading =>
          "${translate("$keys.reading_title")} · "
              "${(progressForState(state) * 100).round()}%",
        _NfcStage.done => translate("$keys.done_title"),
        _ => context.tr(_getTranslationKeyForState(state)),
      };
    };
  }

  String _readingErrorToHintKey(DocumentReadingError error) {
    return switch (error) {
      .unknown => _k("error_generic"),
      .timeoutWaitingForTag => _k("timeout_waiting_for_tag"),
      .tagLost => _k("tag_lost_try_again"),
      .failedToInitiateSession => _k("failed_to_initiate_session"),
      .invalidatedByUser => "",
    };
  }
}

class _UiState {
  final String tipKey;
  final String stateKey;

  _UiState({required this.tipKey, required this.stateKey});
}
