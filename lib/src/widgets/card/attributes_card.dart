import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../models/attributes.dart';
import 'attributes_card_item.dart';
import 'irma_card.dart';

class AttributesCard extends StatelessWidget {
  final List<Attribute> attributes;

  const AttributesCard(this.attributes);

  @override
  Widget build(BuildContext context) {
    //Group attirubtes by credential
    final attributesGroupdByCredential = groupBy(attributes, (Attribute att) => att.credentialInfo.fullId);
    return IrmaCard(
      child: Column(children: [
        //Add an item for each credential
        for (var credentialId in attributesGroupdByCredential.keys)
          Column(
            children: [
              AttributesCardItem(attributesGroupdByCredential[credentialId]!),
              //Add divider when this is not the last item
              if (credentialId != attributesGroupdByCredential.keys.last)
                Divider(
                  color: Colors.grey.shade500,
                )
            ],
          )
      ]),
    );
  }
}
