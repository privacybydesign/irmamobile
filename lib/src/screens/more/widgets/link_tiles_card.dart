import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class LinkTilesCard extends StatelessWidget {
  final List<Widget> children;

  const LinkTilesCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            for (var linkTile in children) ...[
              linkTile,
              if (children.last != linkTile) const Divider(),
            ]
          ],
        ),
      ),
    );
  }
}
