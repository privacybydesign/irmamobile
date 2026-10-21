import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../routing.dart";
import "../../models/schemaless/credential_store.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../models/schemaless/session_state.dart";
import "../../models/session.dart";
import "../../providers/app_locked_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/preferences_provider.dart";
import "../../providers/waiting_request_provider.dart";
import "../../widgets/glass/glass_sheet.dart";
import "../../widgets/glass/sheet_action_row.dart";
import "../pin/pin_screen.dart" show pinStateLine;
import "../pin/providers/pin_unlock_provider.dart";
import "../pin/widgets/waiting_request_card.dart";
import "../pin/yivi_pin_screen.dart";
import "../reset_pin/reset_pin_screen.dart";
import "../session/widgets/issue_flow.dart";
import "../session/widgets/issue_sheet_progress.dart";
import "scanner_screen.dart";

/// Whether the lock screen's scanner sheet carries an issuance past the
/// unlock. [LockGate] keeps its overlay (with the sheet on it) while it
/// does, so the issuance goes on in the sheet.
final lockScannerSheetHolds = ValueNotifier<bool>(false);

/// The QR scanner of the lock screen, as a sheet that goes on after the
/// scan (docs/waiting-request-pin-plan.md, design 4b):
/// 1. the scanner;
/// 2. "Unlock Yivi": who the request is from, as far as Yivi knows before
///    the PIN, and the PIN pad;
/// 3. for an issuance (IRMA or OpenID4VCI), the issuance itself in the same
///    sheet ([IssueFlow] without a type picked first): the offer, the
///    PIN if irmago asks, "Success". Done closes the sheet on the Data tab.
///
/// A disclosure or signature goes full screen after the PIN: the sheet
/// closes as the app unlocks, and the session screen opens as it always
/// does.
class LockScannerSheet extends ConsumerStatefulWidget {
  const LockScannerSheet({super.key});

  @override
  ConsumerState<LockScannerSheet> createState() => _LockScannerSheetState();
}

class _LockScannerSheetState extends ConsumerState<LockScannerSheet>
    with IssueFlow<LockScannerSheet> {
  /// The scanned pointer, waiting for the PIN.
  Pointer? _scanned;

  /// The scan is an issuance: it goes on in this sheet after the PIN.
  bool get _issuance {
    final scanned = _scanned;
    return scanned is SessionPointer && scanned.irmaqr == "issuing";
  }

  String _t(String key, [Map<String, String>? params]) =>
      FlutterI18n.translate(context, key, translationParams: params);

  @override
  void dispose() {
    lockScannerSheetHolds.value = false;
    super.dispose();
  }

  // ---------- the issuance, without a request ----------

  @override
  int? get underlyingSessionId => null;

  @override
  SessionState? get issueRequest => null;

  @override
  IssueSheetSubject issueSubject(CredentialDescriptor d) =>
      IssueSheetSubject.card(d);

  @override
  String issueStopText() => _t("data.add.stop_text");

  @override
  String issueSuccessText(List<schemaless.Credential> cards) => _t(
    cards.length > 1
        ? "issuance.success_feedback.added_many"
        : "issuance.success_feedback.added_one",
    {"name": cards.firstOrNull?.name ?? "", "count": "${cards.length}"},
  );

  @override
  Widget issueSuccessBar(List<schemaless.Credential> cards) => SheetActionRow(
    primaryKey: const Key("sheet_done"),
    primaryLabel: _t("data.add.done"),
    onPrimary: _close,
  );

  /// The lock overlay has no router; a session handed over full screen goes
  /// on the app's own navigator.
  @override
  BuildContext get issueRouteContext =>
      rootNavigatorKey.currentContext ?? context;

  @override
  void issueSessionEnded() => _close();

  // ---------- the scan and the PIN ----------

  void _onScanned(Pointer pointer) {
    ref.read(irmaRepositoryProvider).setPendingPointer(pointer);
    setState(() => _scanned = pointer);
    if (_issuance) {
      // Takes the session that starts on unlock, and keeps the lock
      // overlay (this sheet's home) until the issuance is over.
      issueTakeSession();
      lockScannerSheetHolds.value = true;
    }
  }

  /// Back to the scanner: the scan is dropped, so nothing starts.
  void _back() {
    ref.read(irmaRepositoryProvider).setPendingPointer(null);
    issueReleaseSession();
    lockScannerSheetHolds.value = false;
    setState(() => _scanned = null);
  }

  void _close() {
    if (!mounted) return;
    _letGo();
    Navigator.of(context).pop();
  }

  /// Before the sheet goes: no longer the host for a new session, and the
  /// lock overlay need not stay for it. Here rather than in dispose, where a
  /// provider can't change.
  void _letGo() {
    issueReleaseSession();
    lockScannerSheetHolds.value = false;
  }

  /// Closing with a scan waiting asks first, and drops the scan.
  Future<bool> _confirmClose() async {
    final stop =
        issueAdded != null ||
        !ref.read(appLockedProvider) ||
        await confirmStopWaitingRequest(
          context,
          ref.read(waitingRequestProvider).value,
        );
    if (stop && mounted) {
      if (ref.read(appLockedProvider)) {
        ref.read(irmaRepositoryProvider).setPendingPointer(null);
      }
      _letGo();
    }
    return stop;
  }

  @override
  Widget build(BuildContext context) {
    issueListen();
    // Unlocked: a disclosure or signature opens full screen, so the sheet
    // goes; an issuance stays, for the session that starts now.
    ref.listen<bool>(appLockedProvider, (previous, locked) {
      if (locked || _scanned == null) return;
      if (!_issuance) {
        _close();
        return;
      }
      // The session starts right after the unlock. Should it not come here
      // (another session was going), it has its own screen: the sheet goes.
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted && !issueHasSession) _close();
      });
    });

    return GlassSheetConfirmDismiss(
      ask: _scanned != null,
      confirm: _confirmClose,
      child: GlassSheetPages(
        onBack: issueHasSession ? issueBack : _back,
        pages: [
          KeyedSubtree(
            key: const ValueKey("scanner"),
            child: ScannerScreen(onScanned: _onScanned),
          ),
          if (_scanned != null)
            KeyedSubtree(
              key: const ValueKey("unlock"),
              child: _UnlockPage(onBack: _back),
            ),
          ...issueFlowPages(),
        ],
      ),
    );
  }
}

/// "Unlock Yivi": the request that waits, compact, over the PIN pad. The
/// PIN is the app's unlock ([pinUnlockProvider]), which also refreshes the
/// keyshare token, so the session then needs no PIN of its own. A wrong PIN
/// or a block shows as on the lock screen under the sheet.
class _UnlockPage extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const _UnlockPage({required this.onBack});

  @override
  ConsumerState<_UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends ConsumerState<_UnlockPage> {
  int _resetNonce = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<PinUnlockState>(pinUnlockProvider, (_, next) {
      if (next.pinInvalid && mounted) setState(() => _resetNonce++);
    });
    final state = ref.watch(pinUnlockProvider);
    final waiting = ref.watch(waitingRequestProvider).value;
    final maxPinSize = (ref.watch(longPinProvider).value ?? false)
        ? longPinSize
        : shortPinSize;
    final blockedFor = ref.watch(pinBlockedForProvider).value ?? Duration.zero;
    final blocked = blockedFor.inSeconds > 0;
    final busy = state.authenticateInProgress || state.authenticated;
    final enabled = !blocked && !busy;
    String t(String key) => FlutterI18n.translate(context, key);
    // A wrong PIN or a block, said in the line under the title.
    final line = pinStateLine(context, state, blockedFor);

    void submit(String pin) => ref.read(pinUnlockProvider.notifier).unlock(pin);

    return GlassSheetPage(
      key: const Key("lock_scanner_unlock"),
      title: t("waiting_request.unlock_title"),
      onBack: busy ? null : widget.onBack,
      scrolls: false,
      childClearsBottom: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!busy)
            KeyedSubtree(
              key: ValueKey(_resetNonce),
              child: YiviPinScreen(
                header: waiting == null
                    ? null
                    : WaitingRequestCard(request: waiting, compact: true),
                showMark: false,
                instruction: waiting != null
                    ? t(waitingHeadKey(waiting))
                    : blocked
                    ? t("pin.blocked_title")
                    : t("pin.subtitle"),
                detail:
                    line?.text ??
                    (waiting == null ? null : waitingDetail(context, waiting)),
                detailKind: line == null
                    ? PinDetailKind.info
                    : PinDetailKind.error,
                detailClock: blocked,
                pinError: line != null && !blocked,
                maxPinSize: maxPinSize,
                submitLabel: "pin.unlock",
                enabled: enabled,
                onSubmit: enabled ? submit : (_) {},
                onForgotPin: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ResetPinScreen()),
                ),
                listener: (context, pinState) {
                  if (maxPinSize == shortPinSize &&
                      pinState.pin.length == maxPinSize &&
                      enabled) {
                    submit(pinState.toString());
                  }
                },
              ),
            ),
          if (busy) const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
