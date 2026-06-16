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
    final repo = IrmaRepositoryProvider.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        StreamBuilder(
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
              activeColor: context.colors.secondary,
            );
          },
        ),
        SizedBox(width: context.yivi.smallSpacing),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  style: context.text.bodyLarge,
                  text:
                      '${FlutterI18n.translate(context, 'enrollment.error_reporting.accept.optional')}: ',
                ),
                TextSpan(
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.yivi.brand.link,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _showErrorReportingInfoBottomSheet(context),
                  text: FlutterI18n.translate(
                    context,
                    "enrollment.error_reporting.accept.share_errors",
                  ),
                ),
                TextSpan(
                  style: context.text.bodyMedium,
                  text:
                      ' ${FlutterI18n.translate(context, 'enrollment.error_reporting.accept.with_yivi')}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
