import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';

class IrmaIconButton extends StatelessWidget {
  final IconData icon;
  final Function() onTap;
  final double size;
  final EdgeInsets? padding;
  final String? semanticsLabelKey;

  const IrmaIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 24,
    this.padding,
    this.semanticsLabelKey,
  }) : assert(size >= 2);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final borderRadius = BorderRadius.circular(25.0);

    return Semantics(
      button: true,
      label: semanticsLabelKey != null
          ? FlutterI18n.translate(
              context,
              semanticsLabelKey!,
            )
          : null,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(12),
            child: Icon(
              icon,
              size: size,
              color: theme.neutralExtraDark,
            ),
          ),
        ),
      ),
    );
  }
}
