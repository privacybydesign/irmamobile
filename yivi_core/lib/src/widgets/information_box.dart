import "package:flutter/material.dart";

import "../theme/theme.dart";

class InformationBox extends StatelessWidget {
  final String message;

  const InformationBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: context.yivi.borderRadius,
        border: Border.all(color: context.colors.outlineVariant, width: 1),
      ),
      padding: EdgeInsets.all(context.yivi.defaultSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: context.colors.primary),
          SizedBox(width: context.yivi.smallSpacing),
          Expanded(
            child: Text(
              message,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
