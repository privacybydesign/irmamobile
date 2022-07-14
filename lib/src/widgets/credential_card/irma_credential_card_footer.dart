import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';
import '../irma_button.dart';

class IrmaCredentialCardFooter extends StatelessWidget {
  final String text;
  final bool isObtainable;

  const IrmaCredentialCardFooter({
    required this.text,
    this.isObtainable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: theme.textTheme.caption!.copyWith(
                color: theme.neutral,
              ),
            ),
            SizedBox(height: theme.smallSpacing),
            if (isObtainable)
              IrmaButton(
                label: 'credential.options.reobtain',
                onPressed: () {},
                minWidth: double.infinity,
              )
          ],
        )
      ],
    );
  }
}
