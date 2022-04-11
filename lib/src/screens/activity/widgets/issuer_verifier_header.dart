import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';

class IssuerVerifierHeader extends StatelessWidget {
  final String title;
  final String? logo;

  const IssuerVerifierHeader({required this.title, this.logo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(backgroundColor: Colors.grey.shade300, radius: 24),
        SizedBox(
          width: IrmaTheme.of(context).smallSpacing,
        ),
        Text(
          title,
          style: IrmaTheme.of(context).textTheme.bodyText1,
        ),
      ],
    );
  }
}
