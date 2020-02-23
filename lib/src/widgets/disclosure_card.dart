import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/verifier.dart';
import 'package:irmamobile/src/screens/disclosure/carousel.dart';
import 'package:irmamobile/src/theme/theme.dart';

class DisclosureCard extends StatefulWidget {
  final List<List<VerifierCredential>> issuers;

  static const _indent = 100.0;

  const DisclosureCard(this.issuers) : super();

  @override
  _DisclosureCardState createState() => _DisclosureCardState();
}

class _DisclosureCardState extends State<DisclosureCard> {
  final _lang = 'nl';

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      semanticContainer: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IrmaTheme.of(context).defaultSpacing),
        side: const BorderSide(color: Color(0xFFDFE3E9), width: 1),
      ),
      color: IrmaTheme.of(context).primaryLight,
      child: Column(
        children: [
          SizedBox(height: IrmaTheme.of(context).smallSpacing),
          ...widget.issuers
              .expand(
                (issuerList) => [
                  if (issuerList != widget.issuers[0])
                    Divider(
                      color: IrmaTheme.of(context).grayscale80,
                    ),
                  // TODO: Re-enable this
                  Carousel(candidatesDisCon: DisCon<CredentialAttribute>(const []))
                ],
              )
              .toList(),
          SizedBox(height: IrmaTheme.of(context).smallSpacing),
        ],
      ),
    );
  }

  Widget carouselWidget(VerifierCredential credential) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).mediumSpacing),
      child: Column(
        children: <Widget>[
          ...credential.attributes.entries
              .map((personal) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: DisclosureCard._indent,
                        margin: const EdgeInsets.only(top: 2),
                        child: Text(
                          personal.key.name[_lang],
                          style: IrmaTheme.of(context)
                              .textTheme
                              .body1
                              .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        personal.value[_lang],
                        style: IrmaTheme.of(context).textTheme.body1,
                      ),
                    ],
                  ))
              .toList(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: DisclosureCard._indent,
                  child: Opacity(
                    opacity: 0.8,
                    child: Text(
                      FlutterI18n.translate(context, 'disclosure.issuer'),
                      style: IrmaTheme.of(context)
                          .textTheme
                          .body1
                          .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Text(
                  credential.issuer,
                  style: IrmaTheme.of(context)
                      .textTheme
                      .body1
                      .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
