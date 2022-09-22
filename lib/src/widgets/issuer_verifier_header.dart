import 'package:flutter/material.dart';

import '../screens/activity/widgets/title_initial_uppercased.dart';
import '../theme/theme.dart';

class IssuerVerifierHeader extends StatelessWidget {
  final String title;
  final TextStyle? titleTextStyle;
  final Image? image;

  const IssuerVerifierHeader({
    required this.title,
    this.titleTextStyle,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          radius: 24,
          child: image ?? TitleInitialUpperCased(title),
        ),
        SizedBox(
          width: theme.smallSpacing,
        ),
        Flexible(
          child: Text(
            title,
            style: titleTextStyle ?? theme.textTheme.bodyText1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
