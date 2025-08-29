import 'package:flutter/material.dart';

import '../models/credentials.dart';
import '../theme/theme.dart';
import 'credential_card/yivi_credential_card.dart';

class IssuingDetail extends StatelessWidget {
  final List<MultiFormatCredential> credentials;

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
        child: YiviCredentialCard.fromMultiFormatCredential(credential, compact: false, lowInstanceCountThreshold: 0),
      );
    }).toList();
  }
}
