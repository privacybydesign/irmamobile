import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_button.dart';
import '../../../widgets/irma_text_button.dart';
import '../../../widgets/irma_themed_button.dart';

class EnrollmentNavBar extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback onContinue;

  const EnrollmentNavBar({
    Key? key,
    required this.onPrevious,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      height: 100,
      color: theme.themeData.colorScheme.background,
      padding: EdgeInsets.all(theme.mediumSpacing),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Previous button (or spacer)
          Flexible(
            child: onPrevious == null
                ? Container()
                : IrmaTextButton(
                    label: 'ui.previous',
                    textStyle: theme.hyperlinkTextStyle,
                    onPressed: onPrevious,
                    size: IrmaButtonSize.large,
                  ),
          ),

          // Next button
          Flexible(
            child: IrmaButton(
              label: 'ui.next',
              onPressed: onContinue,
              size: IrmaButtonSize.large,
            ),
          ),
        ],
      ),
    );
  }
}
