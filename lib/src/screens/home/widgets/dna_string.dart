import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class DnaString extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: IrmaTheme.of(context).defaultSpacing,
      ),
      child: Image.asset(
        'assets/non-free/dna_string.png',
        fit: BoxFit.fitWidth,
        width: double.infinity,
      ),
    );
  }
}
