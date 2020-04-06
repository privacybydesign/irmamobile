import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/widgets/card/card.dart';

class RemovalDetail extends StatelessWidget {
  final List<RemovedCredential> removedCredentials;

  const RemovalDetail(this.removedCredentials);

  @override
  Widget build(BuildContext context) {
    return Column(children: _buildCards());
  }

  List<Widget> _buildCards() {
    return removedCredentials.map((credential) {
      return IrmaCard.fromRemovedCredential(
        credential: credential,
        scrollBeyondBoundsCallback: (value) {},
      );
    }).toList();
  }
}
