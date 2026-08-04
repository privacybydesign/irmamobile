import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../../providers/irma_repository_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../widgets/yivi_bottom_sheet.dart";
import "error_reporting_info_bottom_sheet.dart";

class ErrorReportingCheckBox extends StatelessWidget {
  Future<void> _showErrorReportingInfoBottomSheet(BuildContext context) =>
      showYiviBottomSheet(
        context: context,
        titleKey: "enrollment.error_reporting.dialog.title",
        child: ErrorReportingInfoBottomSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final repo = IrmaRepositoryProvider.of(context);

    // The visible label is assembled from three spans so the middle one can
    // open the info sheet. Translating each part once and sharing it with the
    // screen reader label below keeps the spoken sentence identical to the
    // written one in every locale.
    final optional = FlutterI18n.translate(
      context,
      "enrollment.error_reporting.accept.optional",
    );
    final shareErrors = FlutterI18n.translate(
      context,
      "enrollment.error_reporting.accept.share_errors",
    );
    final withYivi = FlutterI18n.translate(
      context,
      "enrollment.error_reporting.accept.with_yivi",
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // The label lives in a sibling widget, so the checkbox itself has no
        // accessible name — merge one in, so a screen reader announces the
        // label together with the checkbox role and its checked state. The
        // rich text keeps its own semantics, which is what makes the
        // info-sheet link reachable.
        MergeSemantics(
          child: Semantics(
            label: "$optional: $shareErrors $withYivi",
            child: StreamBuilder(
              stream: repo.preferences.getReportErrors(),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                final value = snapshot.hasData && snapshot.data!;

                return Checkbox(
                  key: const Key("error_reporting_checkbox"),
                  value: value,
                  onChanged: (isAccepted) {
                    if (isAccepted != null) {
                      repo.preferences.setReportErrors(isAccepted);
                    }
                  },
                  activeColor: theme.themeData.colorScheme.secondary,
                );
              },
            ),
          ),
        ),
        SizedBox(width: theme.smallSpacing),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  text: "$optional: ",
                ),
                TextSpan(
                  style: theme.hyperlinkTextStyle,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _showErrorReportingInfoBottomSheet(context),
                  text: shareErrors,
                ),
                TextSpan(style: theme.textTheme.bodyMedium, text: " $withYivi"),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
