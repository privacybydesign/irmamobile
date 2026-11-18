import "package:cupertino_ui/cupertino_ui.dart";
import "package:flutter/gestures.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../providers/preferences_provider.dart";
import "../../../../theme/yivi_palette.dart";
import "../../../../theme/yivi_space.dart";
import "../../../../util/i18n.dart";
import "../../../../widgets/sheet/glass_sheet.dart";
import "error_reporting_info_bottom_sheet.dart";

/// "Share error messages and app status with Yivi", as a switch. The first
/// part opens the sheet that explains what is shared.
class ErrorReportSwitch extends ConsumerStatefulWidget {
  const ErrorReportSwitch({super.key});

  @override
  ConsumerState<ErrorReportSwitch> createState() => _ErrorReportSwitchState();
}

class _ErrorReportSwitchState extends ConsumerState<ErrorReportSwitch> {
  late final _recognizer = TapGestureRecognizer()
    ..onTap = () => _explain(context);

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  Future<void> _explain(BuildContext context) => showTitledGlassSheet(
    context: context,
    titleKey: "enrollment.error_reporting.dialog.title",
    child: const ErrorReportingInfoBottomSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final shareErrors = context.tr(
      "enrollment.error_reporting.accept.share_errors",
    );
    final withYivi = context.tr("enrollment.error_reporting.accept.with_yivi");

    return Builder(
      builder: (context) {
        final value = ref.watch(reportErrorsProvider);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            YiviSpace.x8,
            YiviSpace.x4,
            YiviSpace.x4,
            YiviSpace.x4,
          ),
          child: Row(
            spacing: YiviSpace.x12,
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
                          recognizer: _recognizer,
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
                    activeTrackColor: palette.primary,
                    onChanged: ref.read(preferencesProvider).reportErrors.set,
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
