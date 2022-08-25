import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_step_indicator.dart';
import '../../../../widgets/translated_text.dart';

class DisclosurePermissionIntroductionInstruction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    Widget _buildStepInstruction(int step) => Padding(
          padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 27,
                width: 27,
                child: IrmaStepIndicator(step: step),
              ),
              SizedBox(width: theme.defaultSpacing),
              Flexible(
                child: TranslatedText(
                  'disclosure_permission.introduction.step_${step.toString()}',
                ),
              ),
            ],
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                'disclosure_permission.introduction.header',
                style: theme.themeData.textTheme.headline5,
              ),
              SizedBox(
                height: theme.smallSpacing,
              ),
              _buildStepInstruction(1),
              _buildStepInstruction(2),
              _buildStepInstruction(3)
            ],
          ),
        )
      ],
    );
  }
}
