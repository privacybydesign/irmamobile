import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/verifier.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/disclosure_card.dart';
import 'package:irmamobile/src/widgets/irma_quote.dart';

class SigningDetail extends StatelessWidget {
  final String signedMessage;
  final List<List<VerifierCredential>> credentails;

  const SigningDetail(this.signedMessage, this.credentails);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(
            left: IrmaTheme.of(context).defaultSpacing,
          ),
          child: IrmaQuote(
            quote: signedMessage,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: IrmaTheme.of(context).defaultSpacing,
            top: IrmaTheme.of(context).defaultSpacing,
          ),
          child: Text(
            FlutterI18n.translate(context, "history.type.signing.subtitle_used_data"),
            style: IrmaTheme.of(context).textTheme.display2,
          ),
        ),
        SizedBox(height: IrmaTheme.of(context).defaultSpacing),
        DisclosureCard(credentails),
      ],
    );
  }
}
