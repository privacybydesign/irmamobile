import "package:cupertino_ui/cupertino_ui.dart";
import "package:flutter/gestures.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../../providers/irma_repository_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../theme/yivi_palette.dart";
import "../../../../widgets/glass/glass_sheet.dart";
import "error_reporting_info_bottom_sheet.dart";

/// "Share error messages and app status with Yivi", as a switch. The first
/// part opens the sheet that explains what is shared.
class ErrorReportSwitch extends StatelessWidget {
  const ErrorReportSwitch({super.key});

  Future<void> _explain(BuildContext context) => showTitledGlassSheet(
    context: context,
    titleKey: "enrollment.error_reporting.dialog.title",
    child: const ErrorReportingInfoBottomSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final theme = IrmaTheme.of(context);
    final preferences = IrmaRepositoryProvider.of(context).preferences;
    final shareErrors = FlutterI18n.translate(
      context,
      "enrollment.error_reporting.accept.share_errors",
    );
    final withYivi = FlutterI18n.translate(
      context,
      "enrollment.error_reporting.accept.with_yivi",
    );

    return StreamBuilder<bool>(
      stream: preferences.getReportErrors(),
      builder: (context, snapshot) {
        final value = snapshot.data ?? false;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                // One node for the sentence, with the sheet as its action
                // (the tappable span would otherwise split it in three).
                child: Semantics(
                  container: true,
                  label: "$shareErrors $withYivi",
                  onTap: () => _explain(context),
                  excludeSemantics: true,
                  child: Text.rich(
                    TextSpan(
                      style: palette.body(14).copyWith(color: palette.heading),
                      children: [
                        TextSpan(
                          text: shareErrors,
                          style: TextStyle(
                            color: palette.link,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _explain(context),
                        ),
                        TextSpan(text: " $withYivi"),
                      ],
                    ),
                  ),
                ),
              ),
              MergeSemantics(
                child: Semantics(
                  label: "$shareErrors $withYivi",
                  child: CupertinoSwitch(
                    key: const Key("error_reporting_switch"),
                    value: value,
                    activeTrackColor: theme.primary,
                    onChanged: preferences.setReportErrors,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
