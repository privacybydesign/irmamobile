import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_button.dart';
import 'irma_themed_button.dart';

class IrmaBottomBar extends StatelessWidget {
  final String? primaryButtonLabel;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onPrimaryDisabledPressed;
  final bool showTooltipOnPrimary;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryPressed;

  const IrmaBottomBar({
    Key? key,
    this.primaryButtonLabel,
    this.onPrimaryPressed,
    this.onPrimaryDisabledPressed,
    this.showTooltipOnPrimary = false,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
  }) : super(key: key);

  Widget _buildPrimaryButton(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: IrmaTheme.of(context).tinySpacing,
        ),
        child: IrmaButton(
          key: const Key('bottom_bar_primary'),
          size: IrmaButtonSize.large,
          onPressed: onPrimaryPressed,
          onPressedDisabled: onPrimaryDisabledPressed,
          label: primaryButtonLabel!,
          color: IrmaTheme.of(context).primaryBlue,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return Expanded(
      child: IrmaButton(
        key: const Key('bottom_bar_secondary'),
        size: IrmaButtonSize.large,
        onPressed: onSecondaryPressed,
        label: secondaryButtonLabel!,
        isSecondary: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      width: mediaQuery.size.width,
      decoration: BoxDecoration(
        color: theme.backgroundBlue,
        border: Border(
          top: BorderSide(
            color: theme.primaryLight,
            width: 2.0,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: mediaQuery.size.height > 450 ? theme.defaultSpacing : theme.smallSpacing,
          horizontal: theme.defaultSpacing,
        ),
        child:
            // Change layout according to limited height (i.e. landscape mode)
            mediaQuery.size.height > 450
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (primaryButtonLabel != null)
                        Row(
                          children: [_buildPrimaryButton(context)],
                        ),
                      if (secondaryButtonLabel != null) ...[
                        SizedBox(
                          height: theme.tinySpacing,
                        ),
                        Row(
                          children: [_buildSecondaryButton(context)],
                        )
                      ]
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (secondaryButtonLabel != null) ...[
                        _buildSecondaryButton(context),
                        SizedBox(
                          width: theme.tinySpacing,
                        )
                      ],
                      if (primaryButtonLabel != null) _buildPrimaryButton(context),
                    ],
                  ),
      ),
    );
  }
}
