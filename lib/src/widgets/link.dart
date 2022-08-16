import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';

class Link extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const Link({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      key: const Key('irma_link'),
      child: InkWell(
        enableFeedback: true,
        onTap: onTap,
        child: Text(
          label,
          style: IrmaTheme.of(context).hyperlinkTextStyle.copyWith(
                decoration: TextDecoration.underline,
              ),
        ),
      ),
    );
  }
}
