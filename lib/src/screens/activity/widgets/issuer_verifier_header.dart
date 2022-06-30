import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class IssuerVerifierHeader extends StatelessWidget {
  final String title;
  final String? logo;

  const IssuerVerifierHeader({
    required this.title,
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          radius: 24,
        ),
        SizedBox(
          width: theme.smallSpacing,
        ),
        Flexible(
          child: Text(
            title,
            style: theme.textTheme.bodyText1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
