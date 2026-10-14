import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "translated_text.dart";

class IrmaDismissible extends StatelessWidget {
  final Widget child;
  final VoidCallback onDismissed;

  /// Corners of the red "Delete" background; defaults to the theme's.
  final BorderRadius? borderRadius;

  const IrmaDismissible({
    required super.key,
    required this.child,
    required this.onDismissed,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final dismissedText = TranslatedText(
      "ui.delete",
      style: theme.textTheme.bodyLarge!.copyWith(color: theme.onPrimary),
    );

    final background = Container(
      decoration: BoxDecoration(
        color: theme.error,
        borderRadius: borderRadius ?? theme.borderRadius,
      ),
      padding: EdgeInsets.all(theme.defaultSpacing),
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
