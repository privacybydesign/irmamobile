import "package:flutter/material.dart";

import "../theme/theme.dart";
import "translated_text.dart";

class IrmaDismissible extends StatelessWidget {
  final Widget child;
  final VoidCallback onDismissed;

  const IrmaDismissible({
    required super.key,
    required this.child,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final dismissedText = TranslatedText(
      "ui.delete",
      style: context.text.bodyLarge!.copyWith(color: Colors.white),
    );

    final background = Container(
      decoration: BoxDecoration(
        color: context.colors.error,
        borderRadius: context.yivi.borderRadius,
      ),
      padding: EdgeInsets.all(context.yivi.defaultSpacing),
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
