import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/custom_button.dart';

class EnrollmentNavBar extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onContinue;

  const EnrollmentNavBar({
    Key? key,
    this.onPrevious,
    this.onContinue,
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
                : Padding(
                    padding: EdgeInsets.only(right: theme.smallSpacing),
                    child: CustomButton(
                      key: const Key('enrollment_previous_button'),
                      style: CustomButtonStyle.outlined,
                      label: 'ui.previous',
                      onPressed: onPrevious,
                    ),
                  ),
          ),
          // Next button
          Flexible(
            child: CustomButton(
              label: 'ui.next',
              onPressed: onContinue,
            ),
          ),
        ],
      ),
    );
  }
}
