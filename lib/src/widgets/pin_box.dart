import 'package:flutter/material.dart';

import '../theme/theme.dart';

class PinBox extends StatelessWidget {
  final double height;

  final String char;

  final bool disabled;
  final bool completed;
  final bool highlightBorder;

  final bool filled;

  PinBox({
    required this.char,
    this.height = 40.0,
    this.disabled = false,
    this.completed = false,
    this.highlightBorder = false,
  }) : filled = char.isNotEmpty;

  Color getBorderColor(IrmaThemeData theme) {
    if (highlightBorder) {
      // the box that is currently highlighted
      return theme.secondary;
    } else if (filled) {
      return Colors.grey.shade300; // filled boxes
    } else {
      // empty boxes that are not highlighted
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: height / 4 * 3,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(theme.tinySpacing)),
        border: Border.all(color: getBorderColor(theme), width: highlightBorder ? 2 : 1),
        color: disabled ? Colors.grey : Colors.white,
      ),
      child: Text(
        char,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: height / 2 + 4,
          height: 22.0 / 18.0,
          color: completed ? theme.secondary : Colors.grey,
        ),
      ),
    );
  }
}
