// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/card_suggestion.dart';
import 'package:irmamobile/src/widgets/heading.dart';

class CardSuggestionGroup extends StatelessWidget {
  final List<CardSuggestion> credentials;
  final String title;
  const CardSuggestionGroup({Key key, this.title, this.credentials}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: credentials.length + 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(
                left: IrmaTheme.of(context).defaultSpacing,
                top: IrmaTheme.of(context).defaultSpacing,
                bottom: IrmaTheme.of(context).smallSpacing,
              ),
              child: Heading(
                title,
                style: IrmaTheme.of(context).textTheme.display3,
              ),
            );
          }

          return credentials[index - 1];
        });
  }
}
