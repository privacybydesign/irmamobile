import "dart:math" as math;

import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";

import "../../package_name.dart";
import "../theme/theme.dart";
import "translated_text.dart";

/// Button look in the document flow screens: 48 high, 16 bold.
enum DocumentFlowButtonStyle {
  /// The red brand stripes.
  primary,

  /// White with a thin dark border.
  outline,

  /// Underlined text without a surface.
  text,
}

class DocumentFlowButton extends StatelessWidget {
  const DocumentFlowButton({
    required this.labelKey,
    required this.onPressed,
    this.style = DocumentFlowButtonStyle.primary,
    super.key,
  });

  static const double height = 48;

  /// The keys of the two button positions, the same as IrmaBottomBar's.
  static const primaryKey = Key("bottom_bar_primary");
  static const secondaryKey = Key("bottom_bar_secondary");

  final String labelKey;
  final VoidCallback? onPressed;
  final DocumentFlowButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final textColor = style == .primary
        ? theme.onPrimary
        : theme.neutralExtraDark;
    final label = Center(
      child: Padding(
        padding: .symmetric(
          horizontal: theme.smallSpacing,
          vertical: theme.tinySpacing,
        ),
        child: TranslatedText(
          labelKey,
          textAlign: .center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: textColor,
            decoration: style == .text ? TextDecoration.underline : null,
            decorationColor: textColor,
          ),
        ),
      ),
    );

    final button = switch (style) {
      .primary => Stack(
        fit: .passthrough,
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: SvgPicture.asset(yiviAsset("ui/btn-bg.svg"), fit: .fill),
            ),
          ),
          Material(
            type: .transparency,
            child: InkWell(onTap: onPressed, child: label),
          ),
        ],
      ),
      .outline => Material(
        color: theme.light,
        child: InkWell(
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: theme.borderRadius,
              border: Border.all(color: theme.neutralExtraDark),
            ),
            child: label,
          ),
        ),
      ),
      .text => Material(
        type: .transparency,
        child: InkWell(onTap: onPressed, child: label),
      ),
    };

    return Semantics(
      button: true,
      enabled: onPressed != null,
      // [height] is the least: a label that wraps at a large text size makes
      // the button taller instead of being cut off.
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          minHeight: height,
        ),
        child: ClipRRect(borderRadius: theme.borderRadius, child: button),
      ),
    );
  }
}

enum DocumentFlowFooterStyle {
  /// Lifted off the content by a soft shadow.
  raised,

  /// On the page, as on the NFC screens.
  flat,
}

/// The bar of buttons at the bottom of a document flow screen.
class DocumentFlowFooter extends StatelessWidget {
  const DocumentFlowFooter({
    required this.buttons,
    this.style = DocumentFlowFooterStyle.raised,
    super.key,
  });

  final List<Widget> buttons;
  final DocumentFlowFooterStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final inset = MediaQuery.paddingOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.light,
        boxShadow: style == .raised
            ? [
                BoxShadow(
                  color: Colors.grey.shade300,
                  offset: const Offset(0, -1),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: .fromLTRB(
          theme.defaultSpacing + inset.left,
          theme.defaultSpacing,
          theme.defaultSpacing + inset.right,
          math.max(theme.largeSpacing, theme.defaultSpacing + inset.bottom),
        ),
        child: Column(
          mainAxisSize: .min,
          spacing: theme.smallSpacing,
          children: buttons,
        ),
      ),
    );
  }
}

/// Title above a line of text on the document flow screens.
TextStyle documentFlowTitleStyle(IrmaThemeData theme) =>
    theme.textTheme.displayMedium!.copyWith(height: 32 / 24);
