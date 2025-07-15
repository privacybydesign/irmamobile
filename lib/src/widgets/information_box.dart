import 'package:flutter/material.dart';

import '../theme/theme.dart';

class InformationBox extends StatelessWidget {
  final String message;

  const InformationBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: theme.borderRadius,
        border: Border.all(color: theme.neutralLight, width: 1),
      ),
      padding: EdgeInsets.all(theme.defaultSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.primary),
          SizedBox(width: theme.smallSpacing),
          Expanded(child: Text(message, textHeightBehavior: const TextHeightBehavior(applyHeightToFirstAscent: false))),
        ],
      ),
    );
  }
}
