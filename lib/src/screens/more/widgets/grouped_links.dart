import 'package:flutter/material.dart';

import '../../../widgets/translated_text.dart';

class LinkTile extends StatelessWidget {
  final IconData iconData;
  final String labelTranslationKey;

  const LinkTile({
    required this.iconData,
    required this.labelTranslationKey,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        iconData,
        size: 32,
      ),
      title: TranslatedText(
        labelTranslationKey,
        //style: theme.textTheme.headline3,
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 30,
      ),
    );
  }
}

class GroupedLinks extends StatelessWidget {
  final List<LinkTile> linkTiles;

  const GroupedLinks({
    required this.linkTiles,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            for (var linkTile in linkTiles) ...[
              linkTile,
              if (linkTiles.last != linkTile) const Divider(),
            ]
          ],
        ),
      ),
    );
  }
}
