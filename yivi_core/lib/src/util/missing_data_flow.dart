import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../providers/missing_data_flow_provider.dart";
import "../theme/theme.dart";
import "../widgets/irma_app_bar.dart";
import "../widgets/missing_data_back_button.dart";
import "../widgets/missing_data_band.dart";
import "navigation.dart";

/// Lets the issuance screens lead back to the missing data checklist when the
/// user came from there.
extension MissingDataFlowNavigation on BuildContext {
  ProviderContainer get _container =>
      ProviderScope.containerOf(this, listen: false);

  /// Whether the user came here from the missing data checklist.
  bool get isCollectingMissingData =>
      _container.read(missingDataFlowProvider) != null;

  /// What the user is collecting data for, or null when they are not.
  MissingDataBandState? get missingDataState =>
      isCollectingMissingData ? _container.read(missingDataBandProvider) : null;

  /// The band for the bottom of an app bar, or null when the user is not
  /// collecting data for a request.
  PreferredSizeWidget? get missingDataBand => isCollectingMissingData
      ? MissingDataBand(
          height: MissingDataBand.heightFor(this, missingDataState),
        )
      : null;

  /// The app bar of an issuance screen. While collecting data for a request
  /// it holds the band and says what is being obtained, "{credential}
  /// ophalen"; otherwise it is the plain app bar for [titleKey]. [onBack]
  /// replaces going back one screen.
  IrmaAppBar issuanceAppBar({required String titleKey, VoidCallback? onBack}) {
    final state = missingDataState;
    if (state == null) {
      return IrmaAppBar(
        bottom: missingDataBand,
        titleTranslationKey: titleKey,
        leading: YiviBackButton(onTap: onBack),
      );
    }

    final theme = IrmaTheme.of(this);

    return IrmaAppBar(
      bottom: missingDataBand,
      leading: MissingDataBackButton(onTap: onBack),
      title: Text(
        FlutterI18n.translate(
          this,
          "missing_data.obtain_title",
          translationParams: {"credential": state.currentName},
        ),
        // Centre the text in its tall line, as the design does.
        style: theme.textTheme.displaySmall!.copyWith(
          color: theme.dark,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
    );
  }

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
