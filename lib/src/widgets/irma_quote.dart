import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';

class IrmaQuote extends StatelessWidget {
  final String? quote;

  const IrmaQuote({required this.quote});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      color: theme.lightBlue,
      child: Padding(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Row(
          children: [
            if (quote != null)
              Flexible(
                  child: Text(
                quote!,
                style: theme.themeData.textTheme.caption,
              ))
          ],
        ),
      ),
    );
  }
}
