import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "../theme/yivi_palette.dart";
import "glass/floating_bar_placement.dart";
import "glass/pill_buttons.dart";

/// Button look in the document flow screens: 56 high pills, 16 bold.
enum DocumentFlowButtonStyle {
  /// The faceted red pill.
  primary,

  /// A plain text pill of the same height, for Cancel and the other choices.
  secondary,

  /// A text link ([TextLink]).
  text,
}

class DocumentFlowButton extends StatelessWidget {
  const DocumentFlowButton({
    required this.labelKey,
    required this.onPressed,
    this.style = DocumentFlowButtonStyle.primary,
    super.key,
  });

  static const double height = PillSize.largeHeight;

  /// The text buttons under the main one have its height.
  static const double secondaryHeight = PillSize.largeHeight;

  /// The keys of the two button positions, the same as IrmaBottomBar's.
  static const primaryKey = Key("bottom_bar_primary");
  static const secondaryKey = Key("bottom_bar_secondary");

  final String labelKey;
  final VoidCallback? onPressed;
  final DocumentFlowButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final label = FlutterI18n.translate(context, labelKey);
    // The pills of the redesign: the faceted red one for the main action,
    // plain text pills for the others (underlined for a text link).
    final Widget button = switch (style) {
      .primary => FancyPillButton(
        label: label,
        onPressed: onPressed,
        size: PillSize.large,
      ),
      .secondary => PillButton(
        label: label,
        onPressed: onPressed,
        style: PillStyle.text,
        size: PillSize.large,
      ),
      .text => TextLink(label: label, onPressed: onPressed),
    };

    // [height] is the least: a label that wraps at a large text size makes
    // the button taller instead of being cut off. MergeSemantics gives the
    // button itself one node with its role, label and enabled state.
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          minHeight: style == .primary ? height : secondaryHeight,
        ),
        child: button,
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

  /// The lowest button is a plain text one, which sits lower.
  bool get _endsWithText => switch (buttons.lastOrNull) {
    DocumentFlowButton b => b.style != DocumentFlowButtonStyle.primary,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final inset = MediaQuery.paddingOf(context);

    // On the page, as the redesign's bottom bars: the content fades out
    // under it instead of a shadow lifting it off.
    final palette = YiviPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: style == .raised
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.background.withValues(alpha: 0),
                  palette.background,
                ],
                stops: const [0, 0.35],
              )
            : null,
        color: style == .raised ? null : palette.background,
      ),
      child: Padding(
        padding: .fromLTRB(
          theme.defaultSpacing + inset.left,
          theme.defaultSpacing,
          theme.defaultSpacing + inset.right,
          // Where every bottom bar ends its buttons (see buttonBottom).
          FloatingBarPlacement.buttonPadding(context, text: _endsWithText),
        ),
        child: Column(
          mainAxisSize: .min,
          spacing: theme.tinySpacing,
          children: buttons,
        ),
      ),
    );
  }
}

/// Title above a line of text on the document flow screens: the display face
/// of the redesign. Takes [theme] for the callers; the colours follow the
/// app brightness through the palette.
TextStyle documentFlowTitleStyle(IrmaThemeData theme) =>
    YiviPalette.forBrightness(
      theme.brightness,
    ).display(24, weight: FontWeight.w700).copyWith(height: 32 / 24);
