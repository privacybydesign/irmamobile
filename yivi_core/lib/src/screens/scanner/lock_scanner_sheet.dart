import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../routing.dart";
import "../../models/session.dart";
import "../../providers/app_locked_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/waiting_request_provider.dart";
import "../../theme/yivi_space.dart";
import "../../util/i18n.dart";
import "../../widgets/sheet/sheet.dart";
import "../pin/pin_entry.dart";
import "../pin/providers/pin_unlock_provider.dart";
import "../pin/widgets/waiting_request_announcement.dart";
import "../reset_pin/reset_pin_screen.dart";
import "../session/issue_flow/issue_flow_controller.dart";
import "../session/issue_flow/issue_flow_pages.dart";
import "../session/issue_flow/issue_sheet.dart";
import "scanner_screen.dart";

/// Whether the lock screen's scanner sheet carries an issuance past the
/// unlock. [LockGate] keeps its overlay (with the sheet on it) while it
/// does, so the issuance goes on in the sheet.
final lockScannerSheetHolds = ValueNotifier<bool>(false);

/// The QR scanner of the lock screen, as a sheet that goes on after the
/// scan:
/// 1. the scanner;
/// 2. "Unlock Yivi": who the request is from, as far as Yivi knows before
///    the PIN, and the PIN pad;
/// 3. for an issuance (IRMA or OpenID4VCI), the issuance itself in the same
///    sheet ([IssueFlowScope] without a type picked first): the offer, the
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

class _LockScannerSheetState extends ConsumerState<LockScannerSheet> {
  final _config = IssueFlowConfig();
  final _keys = IssueSheetKeys();

  IssueFlowController get _flow =>
      ref.read(issueFlowProvider(_config).notifier);

  /// The scanned pointer, waiting for the PIN.
  Pointer? _scanned;

  /// The scan is an issuance: it goes on in this sheet after the PIN.
  bool get _issuance {
    final scanned = _scanned;
    return scanned is SessionPointer && scanned.kind == SessionKind.issuing;
  }

  @override
  void dispose() {
    lockScannerSheetHolds.value = false;
    super.dispose();
  }

  /// The lock overlay has no router; a session handed over full screen goes
  /// on the app's own navigator.
  BuildContext _routeContext() => rootNavigatorKey.currentContext ?? context;

  // ---------- the scan and the PIN ----------

  void _onScanned(Pointer pointer) {
    ref.read(pendingPointerQueueProvider).put(pointer);
    setState(() => _scanned = pointer);
    if (_issuance) {
      // Takes the session that starts on unlock, and keeps the lock
      // overlay (this sheet's home) until the issuance is over.
      _flow.takeSession();
      lockScannerSheetHolds.value = true;
    }
  }

  /// Back to the scanner: the scan is dropped, so nothing starts.
  void _back() {
    ref.read(pendingPointerQueueProvider).clear();
    _letGo();
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
    _flow.releaseSession();
    lockScannerSheetHolds.value = false;
  }

  /// Closing with a scan waiting asks first, and drops the scan.
  Future<bool> _confirmClose() async {
    final stop =
        ref.read(issueFlowProvider(_config)).added != null ||
        !ref.read(appLockedProvider) ||
        await confirmStopWaitingRequest(
          context,
          ref.read(waitingRequestProvider).value,
        );
    if (stop && mounted) {
      if (ref.read(appLockedProvider)) {
        ref.read(pendingPointerQueueProvider).clear();
      }
      _letGo();
    }
    return stop;
  }

  @override
  Widget build(BuildContext context) {
    // The flow's changes build the sheet again, as its pages follow them.
    ref.watch(issueFlowProvider(_config));
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
        if (mounted && !ref.read(issueFlowProvider(_config)).hasSession) {
          _close();
        }
      });
    });

    return IssueFlowScope(
      config: _config,
      keys: _keys,
      host: IssueSheetHost.standalone(
        context,
        onDone: _close,
        onSessionEnded: _close,
        routeContext: _routeContext,
      ),
      builder: (context, flow) => SheetConfirmDismiss(
        ask: _scanned != null,
        confirm: _confirmClose,
        child: SheetPages(
          onBack: flow.now.hasSession ? flow.back : _back,
          pages: [
            KeyedSubtree(
              key: const ValueKey("scanner"),
              // Slides out as the PIN comes in, so the sheet shows behind
              // the PIN pad (it stayed put, dark, under it until the end).
              child: SheetPageMotion(
                child: ScannerScreen(onScanned: _onScanned),
              ),
            ),
            if (_scanned != null)
              KeyedSubtree(
                key: const ValueKey("unlock"),
                child: _UnlockPage(onBack: _back),
              ),
            ...issueFlowPages(flow),
          ],
        ),
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
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pinUnlockProvider);
    final busy = state.authenticateInProgress || state.authenticated;

    return SheetPage.fill(
      key: const Key("lock_scanner_unlock"),
      title: SheetTitle(context.tr("waiting_request.unlock_title")),
      exits: SheetExits(onBack: busy ? null : widget.onBack),
      padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
      child: PinEntry(
        mode: UnlockEntry(
          waiting: ref.watch(waitingRequestProvider).value,
          showMark: false,
          centreUpper: true,
        ),
        feedback: state.feedback.copyWith(busy: busy),
        onSubmit: ref.read(pinUnlockProvider.notifier).unlock,
        onForgotPin: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => ResetPinScreen())),
      ),
    );
  }
}
