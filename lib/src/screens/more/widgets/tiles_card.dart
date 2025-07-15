import 'package:flutter/material.dart';

import '../../../widgets/irma_card.dart';
import '../../../widgets/irma_divider.dart';

class TilesCard extends StatelessWidget {
  final List<Widget> children;

  const TilesCard({required this.children});

  @override
  Widget build(BuildContext context) => IrmaCard(
    padding: EdgeInsets.zero,
    margin: EdgeInsets.zero,
    child: Column(
      children: [
        for (var linkTile in children) ...[linkTile, if (children.last != linkTile) const IrmaDivider()],
      ],
    ),
  );
}
