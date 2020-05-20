import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/card/card.dart';

class IssuingDetail extends StatelessWidget {
  final List<Credential> credentials;

  const IssuingDetail(this.credentials);

  @override
  Widget build(BuildContext context) {
    return Column(children: _buildCards(context));
  }

  List<Widget> _buildCards(BuildContext context) {
    return credentials.map((credential) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: IrmaTheme.of(context).defaultSpacing,
        ),
        child: IrmaCard.fromCredential(
          credential: credential,
          scrollBeyondBoundsCallback: (value) {},
          expanded: true,
          showWarnings: false,
        ),
      );
    }).toList();
  }
}
