import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../screens/embedded_issuance_flows/documents/document_step_in_sheet.dart";
import "../theme/theme.dart";
import "../theme/yivi_palette.dart";
import "glass/floating_bar_placement.dart";
import "glass/glass_sheet.dart";
import "glass/pill_buttons.dart";
import "glass/sheet_action_row.dart";

/// Button look in the document flow screens: 56 high pills, 16 bold.
enum DocumentFlowButtonStyle {
  /// The faceted red pill.
  primary,

  /// A plain text pill of the same height, for Cancel and the other choices.
  secondary,
}

class DocumentFlowButton extends StatelessWidget {
  const DocumentFlowButton({
    required this.labelKey,
    required this.onPressed,
    this.style = DocumentFlowButtonStyle.primary,
    super.key,
  });

  /// Both styles have this height.
  static const double height = PillSize.largeHeight;

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
    // plain text pills for the others.
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
    };

    // [height] is the least: a label that wraps at a large text size makes
    // the button taller instead of being cut off. MergeSemantics gives the
    // button itself one node with its role, label and enabled state.
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          minHeight: height,
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

/// The bar of buttons at the bottom of a document flow screen. In a sheet
/// ([DocumentStepInSheet]) it is the sheet's own: on a phone held upright a
/// [SheetActionRow] where every sheet page has its buttons, so Start sits
/// where "Add" did on the page before; elsewhere the way on goes in the
/// sheet's bar ([SheetSlotAction]) and the other choice is a link.
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
    if (DocumentStepInSheet.of(context)) return _inSheet(context);
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

  Widget _inSheet(BuildContext context) {
    final actions = sheetActions(context, buttons);
    // Upright, in the page's own bottom bar (it puts them there).
    if (SheetSlotAction.atBottom(context)) return actions;
    if (!sheetActionInBar(context)) return SheetBottomBar(child: actions);
    // The way on is in the bar; the other choice, if any, a link at the
    // bottom.
    return Padding(
      padding: EdgeInsets.only(
        bottom: FloatingBarPlacement.buttonBottom(context),
      ),
      child: actions,
    );
  }

  /// [buttons] (all [DocumentFlowButton]s) as the buttons of a step in a
  /// sheet: on a phone held upright the way on and the way back side by
  /// side, in the bottom bar of the sheet page ([SheetSlotAction.atBottom]),
  /// which stays put while the steps change; elsewhere the way on in the
  /// sheet's bar ([SheetSlotAction]) and the way back as a link. Without a
  /// bar: also for the left column of a sheet held sideways ([SheetSplit]).
  static Widget sheetActions(BuildContext context, List<Widget> buttons) {
    final flowButtons = buttons.cast<DocumentFlowButton>();
    final primary = flowButtons.where((b) => b.style == .primary).firstOrNull;
    final secondary = flowButtons.where((b) => b.style != .primary).firstOrNull;
    String? label(DocumentFlowButton? b) =>
        b == null ? null : FlutterI18n.translate(context, b.labelKey);
    SheetAction? asAction(DocumentFlowButton? b) => b == null
        ? null
        : SheetAction(key: b.key, label: label(b)!, onTap: b.onPressed);
    if (SheetSlotAction.atBottom(context)) {
      return SheetSlotAction(
        action: asAction(primary),
        secondary: asAction(secondary),
      );
    }
    if (sheetActionInBar(context)) {
      return SheetSlotAction(
        action: primary == null
            ? null
            : SheetAction(
                key: primary.key,
                label: label(primary)!,
                onTap: primary.onPressed,
              ),
        child: secondary == null
            ? const SizedBox.shrink()
            : Center(
                child: TextLink(
                  key: secondary.key,
                  label: label(secondary)!,
                  onPressed: secondary.onPressed,
                ),
              ),
      );
    }
    return SheetActionRow(
      primaryKey: primary?.key,
      primaryLabel: label(primary),
      onPrimary: primary?.onPressed,
      secondaryKey: secondary?.key,
      secondaryLabel: label(secondary),
      onSecondary: secondary?.onPressed,
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
