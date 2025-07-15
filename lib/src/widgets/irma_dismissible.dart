import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'translated_text.dart';

class IrmaDismissible extends StatelessWidget {
  final Widget child;
  final VoidCallback onDismissed;

  const IrmaDismissible({required super.key, required this.child, required this.onDismissed});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final dismissedText = TranslatedText('ui.delete', style: theme.textTheme.bodyLarge!.copyWith(color: theme.light));

    final background = Container(
      decoration: BoxDecoration(color: theme.error, borderRadius: theme.borderRadius),
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
