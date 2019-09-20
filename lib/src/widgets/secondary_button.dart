import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:irmamobile/src/widgets/theme_button.dart';

class SecondaryButton extends StatelessWidget {
  SecondaryButton({@required this.label, this.onPressed});

  final String label;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return ThemeButton(
      label: label,
      onPressed: onPressed,
      buttonType: 'secondary',
    );
  }
}
