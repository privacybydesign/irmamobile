import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";

import "../../package_name.dart";
import "../theme/theme.dart";
import "missing_data_style.dart";
import "translated_text.dart";

enum MissingDataButtonStyle {
  /// The full width Yivi button.
  primary,

  /// A full width button with a thin outline.
  outline,

  /// The small red button at the end of a list row.
  compact,
}

const _disabledOpacity = 0.45;
const _fullHeight = 48.0;
const _compactHeight = 40.0;
const _compactPadding = 14.0;
const _outlineWidth = 1.0;

/// A button of the missing data screens. Without [onPressed] it is dimmed.
class MissingDataButton extends StatelessWidget {
  final String label;
  final Map<String, String>? labelParams;
  final VoidCallback? onPressed;
  final MissingDataButtonStyle style;

  const MissingDataButton({
    super.key,
    required this.label,
    this.labelParams,
    this.onPressed,
    this.style = MissingDataButtonStyle.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final compact = style == MissingDataButtonStyle.compact;
    final textColor = style == MissingDataButtonStyle.outline
        ? theme.neutralExtraDark
        : theme.light;

    final text = TranslatedText(
      label,
      translationParams: labelParams,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelLarge!.copyWith(
        color: textColor,
        fontSize: compact ? 14 : 16,
      ),
    );

    final button = ClipRRect(
      borderRadius: theme.borderRadius,
      child: switch (style) {
        MissingDataButtonStyle.primary => SizedBox(
          height: _fullHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: SvgPicture.asset(
                    yiviAsset("ui/btn-bg.svg"),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onPressed,
                    child: Center(child: text),
                  ),
                ),
              ),
            ],
          ),
        ),
        MissingDataButtonStyle.outline => SizedBox(
          height: _fullHeight,
          child: Material(
            color: theme.light,
            child: InkWell(
              onTap: onPressed,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: theme.borderRadius,
                  border: Border.all(
                    color: theme.neutralExtraDark,
                    width: _outlineWidth,
                  ),
                ),
                child: Center(child: text),
              ),
            ),
          ),
        ),
        MissingDataButtonStyle.compact => Material(
          color: missingDataActionRed,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _compactHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _compactPadding,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Flexible(child: text)],
                ),
              ),
            ),
          ),
        ),
      },
    );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: onPressed == null
          ? Opacity(opacity: _disabledOpacity, child: button)
          : button,
    );
  }
}
