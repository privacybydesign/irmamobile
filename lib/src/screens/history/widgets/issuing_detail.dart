import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/widgets/card/card.dart';

class IssuingDetail extends StatelessWidget {
  final List<Credential> credentials;

  const IssuingDetail(this.credentials);

  @override
  Widget build(BuildContext context) {
    return Column(children: _buildCards());
  }

  List<Widget> _buildCards() {
    return credentials.map((credential) {
      return IrmaCard.fromCredential(
        credential: credential,
        scrollBeyondBoundsCallback: (value) {},
      );
    }).toList();
  }
}
