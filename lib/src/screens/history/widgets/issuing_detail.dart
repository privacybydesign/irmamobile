import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/widgets/card/card.dart';

class IssuingDetail extends StatelessWidget {
  final List<Credential> credentials;

  const IssuingDetail(this.credentials);

  @override
  Widget build(BuildContext context) {
    return Column(children: _generateCards());
  }

  List<Widget> _generateCards() {
    final widgets = <Widget>[];
    for (final Credential credential in credentials) {
      widgets.add(IrmaCard(credential: credential, scrollBeyondBoundsCallback: (value) {}));
    }
    return widgets;
  }
}
