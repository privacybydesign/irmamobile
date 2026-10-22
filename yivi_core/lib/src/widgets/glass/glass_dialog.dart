import "dart:io";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "glass_surface.dart";

/// The colour of a dialog's icon disc, after what the dialog is about.
enum DialogTone { neutral, info, success, warning, danger }

/// The round disc with an icon at the top of a [GlassDialog] or a status
/// screen: a soft fill with the icon in the matching strong colour.
class ToneDisc extends StatelessWidget {
  final IconData icon;
  final DialogTone tone;
  final double size;

  const ToneDisc({
    super.key,
    required this.icon,
    this.tone = DialogTone.neutral,
    this.size = 56,
  });

  /// Fill and icon colour of [tone].
  static (Color, Color) colors(YiviPalette palette, DialogTone tone) =>
      switch (tone) {
        DialogTone.neutral => (palette.infoSurface, palette.heading),
        DialogTone.info => (palette.infoSurface, palette.link),
        DialogTone.success => (palette.successSurface, palette.successText),
        DialogTone.warning => (palette.warningSurface, palette.warningText),
        DialogTone.danger => (palette.errorSurface, palette.danger),
      };

  @override
  Widget build(BuildContext context) {
    final (fill, ink) = colors(YiviPalette.of(context), tone);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: size / 2, color: ink),
      ),
    );
  }
}

/// A dialog in the glass style: a frosted card with 32 pt corners, an
/// optional icon disc, a centred title and message, and the actions stacked
/// below as pills (the primary one first).
class GlassDialog extends StatelessWidget {
  final String title;

  /// The message under the title. Use [body] for anything richer.
  final String? message;

  /// Shown between the message and the actions, e.g. a text field.
  final Widget? body;

  /// Shown above the title, usually a [ToneDisc].
  final Widget? icon;

  /// Buttons, top to bottom. Leave empty when [body] holds its own buttons.
  final List<Widget> actions;

  final Key? titleKey;
  final Key? messageKey;
  final Key? cardKey;

  const GlassDialog({
    super.key,
    required this.title,
    this.message,
    this.body,
    this.icon,
    this.actions = const [],
    this.titleKey,
    this.messageKey,
    this.cardKey,
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
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(child: icon),
          ),
        Semantics(
          // iOS reads the route name and the title twice; name it elsewhere.
          namesRoute: !Platform.isIOS,
          label: FlutterI18n.translate(context, "accessibility.alert"),
          child: Text(
            title,
            key: titleKey,
            textAlign: TextAlign.center,
            style: palette
                .display(20, weight: FontWeight.w700)
                .copyWith(height: 28 / 20),
          ),
        ),
        if ((message ?? "").isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message!,
              key: messageKey,
              textAlign: TextAlign.center,
              style: palette.body(15).copyWith(height: 22 / 15),
            ),
          ),
        if (body != null)
          Padding(padding: const EdgeInsets.only(top: 16), child: body),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: landscape
                ? Row(
                    spacing: 10,
                    children: [
                      for (final a in actions.reversed) Expanded(child: a),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: actions,
                  ),
          ),
      ],
    );

    return AnimatedPadding(
      padding:
          MediaQuery.viewInsetsOf(context) +
          const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                child: GlassSurface(
                  key: cardKey,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(YiviCorners.sheet)),
                  ),
                  fill: MediaQuery.highContrastOf(context)
                      ? palette.surface
                      : palette.glassStrongFill,
                  padding: const EdgeInsets.all(24),
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
