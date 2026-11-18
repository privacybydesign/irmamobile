import "dart:io";

import "package:material_ui/material_ui.dart";

import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../theme/yivi_tone.dart";
import "../../util/adaptive_layout.dart";
import "../../util/i18n.dart";
import "../buttons/pill_buttons.dart";
import "../surfaces/surface.dart";

/// The round disc with an icon at the top of a [YiviDialog] or a status
/// screen: a soft fill with the icon in the matching strong colour.
class ToneDisc extends StatelessWidget {
  final IconData icon;
  final YiviTone tone;
  final double size;

  /// Null: half of [size].
  final double? iconSize;

  /// What the icon says, when the text next to it does not ("yes", "no").
  final String? semanticLabel;

  const ToneDisc({
    super.key,
    required this.icon,
    this.tone = YiviTone.neutral,
    this.size = 56,
    this.iconSize,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final (fill, ink) = YiviPalette.of(context).tone(tone);
    final disc = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize ?? size / 2, color: ink),
    );
    final label = semanticLabel;
    return label == null
        ? ExcludeSemantics(child: disc)
        : Semantics(label: label, excludeSemantics: true, child: disc);
  }
}

/// The app's dialog: a solid card with 32 pt corners, an optional icon
/// disc, a centred title and message, and the actions stacked below as pills
/// (the primary one first). For a yes/no question, see [showConfirmDialog].
class YiviDialog extends StatelessWidget {
  final String title;

  /// The message under the title. Use [body] for anything richer.
  final String? message;

  /// Shown between the message and the actions, e.g. a text field.
  final Widget? body;

  /// Shown above the title, usually a [ToneDisc].
  final Widget? icon;

  /// Buttons, top to bottom. Leave empty when [body] holds its own buttons.
  final List<Widget> actions;

  /// The key of the card, for tests; by default `dialog`. The title and the
  /// message have the keys `dialog_title` and `dialog_message`.
  final Key cardKey;

  const YiviDialog({
    super.key,
    required this.title,
    this.message,
    this.body,
    this.icon,
    this.actions = const [],
    this.cardKey = const Key("dialog"),
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    // A phone held sideways has little height: the dialog wider, its
    // buttons side by side, the first (the safe answer) at the right.
    final landscape = usePhoneLandscape(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(bottom: YiviSpace.x12),
            child: Center(child: icon),
          ),
        Semantics(
          // iOS reads the route name and the title twice; name it elsewhere.
          namesRoute: !Platform.isIOS,
          label: context.tr("accessibility.alert"),
          child: Text(
            title,
            key: const Key("dialog_title"),
            textAlign: TextAlign.center,
            style: palette.titleSmall.copyWith(height: 28 / 20),
          ),
        ),
        if ((message ?? "").isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: YiviSpace.x8),
            child: Text(
              message!,
              key: const Key("dialog_message"),
              textAlign: TextAlign.center,
              style: palette.body(15).copyWith(height: 22 / 15),
            ),
          ),
        if (body != null)
          Padding(
            padding: const EdgeInsets.only(top: YiviSpace.x16),
            child: body,
          ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: YiviSpace.x24),
            child: landscape
                ? Row(
                    spacing: YiviSpace.x12,
                    children: [
                      for (final a in actions.reversed) Expanded(child: a),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: YiviSpace.x4,
                    children: actions,
                  ),
          ),
      ],
    );

    return AnimatedPadding(
      // Centred in the safe area, clear of a side panel or a notch.
      padding:
          MediaQuery.viewInsetsOf(context) +
          EdgeInsets.only(
            left: MediaQuery.paddingOf(context).left,
            right: MediaQuery.paddingOf(context).right,
          ) +
          const EdgeInsets.symmetric(
            horizontal: YiviSpace.x32,
            vertical: YiviSpace.x16,
          ),
      duration: const Duration(milliseconds: 100),
      curve: Curves.decelerate,
      child: MediaQuery.removeViewInsets(
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        context: context,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 280,
              maxWidth: landscape ? 500 : 420,
            ),
            child: Semantics(
              scopesRoute: true,
              explicitChildNodes: true,
              child: Material(
                type: MaterialType.transparency,
                child: Surface(
                  key: cardKey,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(YiviCorners.dialog),
                    ),
                  ),
                  fill: palette.surface,
                  padding: const EdgeInsets.all(YiviSpace.x24),
                  child: SingleChildScrollView(child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks a yes/no question in a [YiviDialog]: the [titleKey] and the
/// [messageKey] (translation keys, with [messageParams]), the confirm button
/// (red when confirming deletes or resets something, [destructive]) above a
/// cancel text button. True when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String titleKey,
  required String messageKey,
  Map<String, String>? messageParams,
  String confirmKey = "ui.confirm",
  String cancelKey = "ui.cancel",
  bool destructive = false,
  Widget? icon,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) {
        void close(bool confirmed) => Navigator.of(context).pop(confirmed);
        return YiviDialog(
          icon: icon,
          title: context.tr(titleKey),
          message: context.tr(messageKey, messageParams),
          actions: [
            if (destructive)
              PillButton(
                key: const Key("dialog_confirm_button"),
                label: context.tr(confirmKey),
                onPressed: () => close(true),
                style: PillStyle.dangerFilled,
              )
            else
              FancyPillButton(
                key: const Key("dialog_confirm_button"),
                label: context.tr(confirmKey),
                onPressed: () => close(true),
                size: PillSize.regular,
              ),
            PillButton(
              key: const Key("dialog_cancel_button"),
              label: context.tr(cancelKey),
              onPressed: () => close(false),
              style: PillStyle.text,
              size: PillSize.regular,
            ),
          ],
        );
      },
    ) ??
    false;
