import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../models/mrz.dart";
import "../../../providers/ocr_processor_provider.dart";
import "document_flow_steps.dart";

/// Which document issues [credentialId] (`pbdf.pbdf.passport` and its
/// staging twin, and so on), if any.
DocumentType? documentTypeOf(String credentialId) =>
    switch (credentialId.split(".").last) {
      "passport" => .passport,
      "idcard" => .identityCard,
      "drivinglicence" => .drivingLicence,
      _ => null,
    };

/// Adding a document in the Change sheet: the same screens as the full-screen
/// routes ([DocumentFlowSteps]): instruction, camera or manual entry, chip.
/// They run in a navigator of their own inside the sheet, so their back
/// buttons stay in the flow; back from the instruction is [onBack]. The chip
/// read starts the issuance through `handlePointer`, which hands it to the
/// sheet waiting for it. The face check, when the issuer asks for one, opens
/// full-screen above the sheet.
class DocumentSheetStep extends ConsumerStatefulWidget {
  final DocumentType type;

  /// Back from the instruction, to the details.
  final VoidCallback onBack;

  /// Cancel on the instruction: asks before stopping.
  final VoidCallback onCancel;

  /// The chip screen's own cancel, already confirmed there.
  final VoidCallback onStopped;

  const DocumentSheetStep({
    super.key,
    required this.type,
    required this.onBack,
    required this.onCancel,
    required this.onStopped,
  });

  @override
  ConsumerState<DocumentSheetStep> createState() => _DocumentSheetStepState();
}

class _DocumentSheetStepState extends ConsumerState<DocumentSheetStep> {
  final _navigator = GlobalKey<NavigatorState>();

  /// Under the instruction, so popping the instruction is noticed (see
  /// [_PopToRootObserver]) and leaves the flow.
  final _root = PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
  );
  late final _observer = _PopToRootObserver(_root, () => widget.onBack());

  /// The chip screen is open: the camera reports a read more than once.
  var _reading = false;

  void _push(WidgetBuilder builder) =>
      _navigator.currentState?.push(MaterialPageRoute<void>(builder: builder));

  void _pop() => _navigator.currentState?.maybePop();

  /// Start on the instruction: the camera, or typing it in on a device
  /// without one.
  void _capture() {
    if (ref.read(ocrProcessorProvider) == null) {
      _push((_) => _manual());
    } else {
      _push(
        (_) => DocumentFlowSteps.reader(
          widget.type,
          onRead: _read,
          onManual: () => _push((_) => _manual()),
          onCancel: _pop,
        ),
      );
    }
  }

  Widget _manual() =>
      DocumentFlowSteps.manualEntry(widget.type, onRead: _read, onCancel: _pop);

  void _read(ScannedMrz mrz) {
    if (_reading) return;
    _reading = true;
    _navigator.currentState
        ?.push(
          MaterialPageRoute<void>(
            builder: (_) =>
                DocumentFlowSteps.nfc(mrz, onCancel: widget.onStopped),
          ),
        )
        .whenComplete(() => _reading = false);
  }

  @override
  Widget build(BuildContext context) {
    // The screens' bars sit at the top of the sheet, not under a status bar.
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      // System back steps back in the flow first.
      child: NavigatorPopHandler(
        onPopWithResult: (_) => _navigator.currentState?.maybePop(),
        child: Navigator(
          key: _navigator,
          observers: [_observer],
          onGenerateInitialRoutes: (_, _) => [
            _root,
            MaterialPageRoute<void>(
              builder: (_) => DocumentFlowSteps.instruction(
                widget.type,
                onStart: _capture,
                onCancel: widget.onCancel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopToRootObserver extends NavigatorObserver {
  final Route<void> root;
  final VoidCallback onRoot;

  _PopToRootObserver(this.root, this.onRoot);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == root) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onRoot());
    }
  }
}
