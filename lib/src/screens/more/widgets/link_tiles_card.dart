import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_card.dart';
import '../../../widgets/irma_divider.dart';

class LinkTilesCard extends StatelessWidget {
  final List<Widget> children;

  const LinkTilesCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.symmetric(
        horizontal: theme.smallSpacing,
      ),
      child: Column(
        children: [
          for (var linkTile in children) ...[
            linkTile,
            if (children.last != linkTile) const IrmaDivider(),
          ]
        ],
      ),
    );
  }
}
