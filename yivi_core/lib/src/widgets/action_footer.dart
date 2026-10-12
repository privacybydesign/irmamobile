import "dart:math" as math;

import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "translated_text.dart";
import "yivi_themed_button.dart";

const _topShadowOffset = Offset(0, -1);
const _shadowBlur = 6.0;
const _outlineWidth = 1.0;

/// The footer of the redesigned screens: a primary button with an outlined
/// secondary button under it, on a white block with a soft shadow on top.
class ActionFooter extends StatelessWidget {
  final String primaryLabel;
  final IconData? primaryTrailingIcon;
  final VoidCallback? onPrimaryPressed;
  final String secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  const ActionFooter({
    super.key,
    required this.primaryLabel,
    this.primaryTrailingIcon,
    this.onPrimaryPressed,
    required this.secondaryLabel,
    this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.light,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: _shadowBlur,
            offset: _topShadowOffset,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: theme.defaultSpacing,
        right: theme.defaultSpacing,
        top: theme.defaultSpacing,
        bottom: math.max(
          theme.largeSpacing,
          theme.defaultSpacing + bottomInset,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.smallSpacing,
        children: [
          YiviThemedButton(
            key: const Key("action_footer_primary"),
            label: primaryLabel,
            size: YiviButtonSize.standard,
            trailingIcon: primaryTrailingIcon,
            onPressed: onPrimaryPressed,
          ),
          _OutlinedButton(
            key: const Key("action_footer_secondary"),
            label: secondaryLabel,
            onPressed: onSecondaryPressed,
          ),
        ],
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _OutlinedButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Semantics(
      button: true,
      child: SizedBox(
        height: YiviButtonSize.standard.value,
        child: Material(
          color: theme.light,
          shape: RoundedRectangleBorder(
            borderRadius: theme.borderRadius,
            side: BorderSide(
              color: theme.neutralExtraDark,
              width: _outlineWidth,
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            customBorder: RoundedRectangleBorder(
              borderRadius: theme.borderRadius,
            ),
            child: Center(
              child: TranslatedText(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge!.copyWith(
                  color: theme.neutralExtraDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
