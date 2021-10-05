// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/cupertino.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/disclosure/models/disclosure_credential.dart';

// The Offstage in the Carousel widget requires this widget to persist a constant height.
class CarouselCredentialFooter extends StatelessWidget {
  static const _footerColumnWidth = 60.0;

  final DisclosureCredential credential;

  const CarouselCredentialFooter({Key key, this.credential}) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: _footerColumnWidth,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text(
                      FlutterI18n.translate(context, 'disclosure.credential_name'),
                      style: IrmaTheme.of(context)
                          .textTheme
                          .bodyText2
                          .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: IrmaTheme.of(context).smallSpacing),
                    child: Text(
                      getTranslation(context, credential.credentialInfo.credentialType.name),
                      style: IrmaTheme.of(context)
                          .textTheme
                          .bodyText2
                          .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: _footerColumnWidth,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text(
                      FlutterI18n.translate(context, 'disclosure.issuer'),
                      style: IrmaTheme.of(context)
                          .textTheme
                          .bodyText2
                          .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: IrmaTheme.of(context).smallSpacing),
                    child: Text(
                      getTranslation(context, credential.issuer),
                      style: IrmaTheme.of(context)
                          .textTheme
                          .bodyText2
                          .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
