import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'translated_text.dart';

class IrmaProgressIndicator extends StatelessWidget {
  final int stepCount;
  final int step;

  const IrmaProgressIndicator({
    Key? key,
    required this.step,
    required this.stepCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TranslatedText(
            'ui.step_of_steps',
            translationParams: {
              "i": step.toString(),
              "n": stepCount.toString(),
            },
            style: TextStyle(
              fontSize: 12,
              color: theme.themeData.colorScheme.secondary,
            ),
          ),
          SizedBox(height: theme.smallSpacing),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: step / stepCount,
                    color: theme.success,
                    backgroundColor: Colors.grey.shade300,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
