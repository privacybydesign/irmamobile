import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/missing_data_flow_provider.dart";

/// Ends the missing data flow once the route of [child] is visible again, as
/// the issuance screens lead back to it. Wraps both the list and the share
/// screen, because the list is replaced by the share screen while the user is
/// still inside an issuance flow.
class MissingDataFlowReset extends ConsumerStatefulWidget {
  final Widget child;

  const MissingDataFlowReset({super.key, required this.child});

  @override
  ConsumerState<MissingDataFlowReset> createState() =>
      _MissingDataFlowResetState();
}

class _MissingDataFlowResetState extends ConsumerState<MissingDataFlowReset> {
  bool _wasCovered = false;

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
