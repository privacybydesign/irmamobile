import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/card/card.dart';

class RemovalDetail extends StatelessWidget {
  final List<RemovedCredential> removedCredentials;

  const RemovalDetail(this.removedCredentials);

  @override
  Widget build(BuildContext context) {
    return Column(children: _buildCards(context));
  }

  List<Widget> _buildCards(BuildContext context) {
    return removedCredentials.map((credential) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: IrmaTheme.of(context).defaultSpacing,
        ),
        child: IrmaCard.fromRemovedCredential(
          credential: credential,
          scrollBeyondBoundsCallback: (value) {},
        ),
      );
    }).toList();
  }
}
