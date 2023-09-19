import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_repository_provider.dart';
import 'error_reporting_info_bottom_sheet.dart';

class ErrorReportingCheckBox extends StatelessWidget {
  _showErrorReportingInfoBottomSheet(BuildContext context) async => showModalBottomSheet<void>(
        context: context,
        builder: (_) => ErrorReportingInfoBottomSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final repo = IrmaRepositoryProvider.of(context);

    final double fontSize = theme.textTheme.bodyMedium!.fontSize!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        StreamBuilder(
          stream: repo.preferences.getReportErrors(),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            final value = snapshot.hasData && snapshot.data!;

            return Checkbox(
              key: const Key('error_reporting_checkbox'),
              value: value,
              onChanged: (isAccepted) {
                if (isAccepted != null) {
                  repo.preferences.setReportErrors(isAccepted);
                }
              },
              fillColor: MaterialStateColor.resolveWith(
                (_) => theme.themeData.colorScheme.secondary,
              ),
            );
          },
        ),
        SizedBox(
          width: theme.smallSpacing,
        ),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  text: FlutterI18n.translate(
                        context,
                        'enrollment.error_reporting.accept.optional',
                      ) +
                      ': ',
                ),
                TextSpan(
                  style: theme.hyperlinkTextStyle.copyWith(
                    fontSize: fontSize,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () => _showErrorReportingInfoBottomSheet(context),
                  text: FlutterI18n.translate(
                    context,
                    'enrollment.error_reporting.accept.share_errors',
                  ),
                ),
                TextSpan(
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: fontSize,
                  ),
                  text: ' ' +
                      FlutterI18n.translate(
                        context,
                        'enrollment.error_reporting.accept.with_yivi',
                      ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
