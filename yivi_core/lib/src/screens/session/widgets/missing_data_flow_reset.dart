import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/missing_data_flow_provider.dart";

/// Ends the missing data flow of [sessionId] once the route of [child] is
/// visible again, as the issuance screens lead back to it, or once it is
/// removed. Wraps both the list and the share screen, because the list is
/// replaced by the share screen while the user is still inside an issuance
/// flow.
class MissingDataFlowReset extends ConsumerStatefulWidget {
  final int sessionId;
  final Widget child;

  const MissingDataFlowReset({
    super.key,
    required this.sessionId,
    required this.child,
  });

  @override
  ConsumerState<MissingDataFlowReset> createState() =>
      _MissingDataFlowResetState();
}

class _MissingDataFlowResetState extends ConsumerState<MissingDataFlowReset> {
  late final MissingDataFlowNotifier _flow;
  bool _wasCovered = false;

  @override
  void initState() {
    super.initState();
    _flow = ref.read(missingDataFlowProvider.notifier);
  }

  @override
  void dispose() {
    // Providers cannot change while the tree is being torn down.
    final sessionId = widget.sessionId;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _flow.clearForSession(sessionId),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = ModalRoute.isCurrentOf(context) ?? true;
    if (!isCurrent) {
      _wasCovered = true;
    } else if (_wasCovered) {
      _wasCovered = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(missingDataFlowProvider.notifier).clear();
      });
    }

    return widget.child;
  }
}
