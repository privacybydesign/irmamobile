import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';

class IrmaQuote extends StatelessWidget {
  final String? quote;
  final RichText? richQuote;
  final Color? color;

  const IrmaQuote({
    this.quote,
    this.richQuote,
    this.color,
  })  : assert(
          quote != null || richQuote != null,
          "No quote given. Set quote or richQuote.",
        ),
        assert(
          quote == null || richQuote == null,
          "Either set quote or richQuote, not both.",
        );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      color: color ?? theme.surfaceSecondary,
      child: Padding(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Row(
          children: [
            Flexible(
              child: quote != null
                  ? Text(
                      quote!,
                      style: theme.themeData.textTheme.caption,
                    )
                  : richQuote!,
            )
          ],
        ),
      ),
    );
  }
}
