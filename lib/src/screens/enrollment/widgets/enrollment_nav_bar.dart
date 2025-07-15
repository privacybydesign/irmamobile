import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/yivi_themed_button.dart';

class EnrollmentNavBar extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onContinue;

  const EnrollmentNavBar({
    super.key,
    this.onPrevious,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Semantics(
      button: true,
      child: Container(
        height: 100,
        color: theme.themeData.colorScheme.surface,
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
                      child: YiviThemedButton(
                        key: const Key('enrollment_previous_button'),
                        style: YiviButtonStyle.outlined,
                        label: 'ui.previous',
                        onPressed: onPrevious,
                      ),
                    ),
            ),
            // Next button
            Flexible(
              child: YiviThemedButton(
                key: const Key('enrollment_next_button'),
                label: 'ui.next',
                onPressed: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
