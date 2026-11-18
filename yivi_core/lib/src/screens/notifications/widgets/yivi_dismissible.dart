import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../widgets/text/translated_text.dart";

class YiviDismissible extends StatelessWidget {
  final Widget child;
  final VoidCallback onDismissed;

  /// Corners of the red "Delete" background; defaults to the theme's.
  final BorderRadius? borderRadius;

  const YiviDismissible({
    required super.key,
    required this.child,
    required this.onDismissed,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = YiviTheme.of(context);

    final dismissedText = TranslatedText(
      "ui.delete",
      style: theme.textTheme.bodyLarge!.copyWith(color: Colors.white),
    );

    final background = Container(
      decoration: BoxDecoration(
        color: YiviPalette.of(context).danger,
        borderRadius: borderRadius ?? theme.borderRadius,
      ),
      padding: const EdgeInsets.all(YiviSpace.x16),
      alignment: Alignment.centerRight,
      child: dismissedText,
    );

    return Dismissible(
      key: super.key!,
      onDismissed: (_) => onDismissed(),
      direction: DismissDirection.endToStart,
      background: background,
      child: child,
    );
  }
}
