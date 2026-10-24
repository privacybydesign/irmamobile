import "package:material_ui/material_ui.dart";

import "../theme/yivi_corners.dart";
import "../theme/yivi_palette.dart";
import "glass/glass_dialog.dart";
import "glass/glass_surface.dart";

/// A frosted card for dialogs that lay out their own content.
class YiviDialog extends StatelessWidget {
  const YiviDialog({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return AnimatedPadding(
      // Centred in the safe area, clear of a side panel or a notch.
      padding:
          MediaQuery.viewInsetsOf(context) +
          EdgeInsets.only(
            left: MediaQuery.paddingOf(context).left,
            right: MediaQuery.paddingOf(context).right,
          ) +
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
            constraints: const BoxConstraints(maxWidth: 420),
            child: Semantics(
              scopesRoute: true,
              explicitChildNodes: true,
              child: Material(
                type: MaterialType.transparency,
                child: GlassSurface(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(YiviCorners.dialog),
                    ),
                  ),
                  fill: MediaQuery.highContrastOf(context)
                      ? palette.surface
                      : palette.glassStrongFill,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A dialog with a title, a message and [child] below them (usually its
/// buttons), in the glass style of [GlassDialog].
class IrmaDialog extends StatelessWidget {
  final String title;
  final String content;
  final Widget child;

  /// Shown above the title, usually a [ToneDisc].
  final Widget? icon;

  const IrmaDialog({
    required this.title,
    required this.content,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      cardKey: const Key("irma_dialog"),
      titleKey: const Key("irma_dialog_title"),
      messageKey: const Key("irma_dialog_content"),
      icon: icon,
      title: title,
      message: content,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.only(top: 16), child: child),
        ],
      ),
    );
  }
}
