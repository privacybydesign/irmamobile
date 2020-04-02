import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/widgets/disclosure/carousel.dart';
import 'package:irmamobile/src/theme/theme.dart';

class DisclosureCard extends StatefulWidget {
  final ConDisCon<Attribute> candidatesConDisCon;

  static const _indent = 100.0;

  const DisclosureCard({this.candidatesConDisCon}) : super();

  @override
  _DisclosureCardState createState() => _DisclosureCardState();
}

class _DisclosureCardState extends State<DisclosureCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      semanticContainer: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IrmaTheme.of(context).defaultSpacing),
        side: const BorderSide(color: Color(0xFFDFE3E9), width: 1),
      ),
      color: IrmaTheme.of(context).primaryLight,
      child: Column(
        children: [
          SizedBox(height: IrmaTheme.of(context).smallSpacing),
          ...widget.candidatesConDisCon
              .asMap()
              .entries
              .expand(
                (entry) => [
                  // Display a divider except for the first element
                  if (entry.key != 0)
                    Divider(
                      color: IrmaTheme.of(context).grayscale80,
                    ),
                  Carousel(candidatesDisCon: entry.value)
                ],
              )
              .toList(),
          SizedBox(height: IrmaTheme.of(context).smallSpacing),
        ],
      ),
    );
  }
}
