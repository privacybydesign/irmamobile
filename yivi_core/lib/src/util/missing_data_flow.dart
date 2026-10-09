import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../providers/missing_data_flow_provider.dart";
import "../widgets/missing_data_band.dart";
import "navigation.dart";

/// Lets the issuance screens lead back to the missing data checklist when the
/// user came from there.
extension MissingDataFlowNavigation on BuildContext {
  bool get isCollectingMissingData =>
      ProviderScope.containerOf(
        this,
        listen: false,
      ).read(missingDataFlowProvider) !=
      null;

  /// The band for the bottom of an app bar, or null when the user is not
  /// collecting data for a request.
  PreferredSizeWidget? get missingDataBand => isCollectingMissingData
      ? MissingDataBand(height: MissingDataBand.heightFor(this))
      : null;

  /// The label for the secondary button of an issuance screen: "back to the
  /// list" while collecting data for a request, [cancelKey] otherwise.
  String missingDataBackLabel(String cancelKey) =>
      isCollectingMissingData ? "missing_data.back_to_list" : cancelKey;

  /// Goes back to the checklist while collecting data for a request, and runs
  /// [onCancel] otherwise.
  VoidCallback missingDataBack(VoidCallback onCancel) => () {
    if (isCollectingMissingData) {
      popToUnderlyingSession();
    } else {
      onCancel();
    }
  };
}
