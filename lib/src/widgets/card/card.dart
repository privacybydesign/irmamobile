import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/card/card_footer.dart';
import 'package:irmamobile/src/widgets/card/irma_card_theme.dart';

import 'card_attributes.dart';
import 'card_menu.dart';

class IrmaCard extends StatelessWidget {
  static const _borderRadius = Radius.circular(15.0);
  static const _transparentBlack = Color(0x77000000);
  static const _blurRadius = 4.0;

  final String lang = 'nl';

  final CredentialInfo credentialInfo;
  final Attributes attributes;
  DateTime expiryDate;

  Function() onRefreshCredential;
  Function() onDeleteCredential;

  final void Function(double) scrollBeyondBoundsCallback;

  final IrmaCardTheme cardTheme;
  final bool short;

  IrmaCard.fromCredential({
    Credential credential,
    this.onRefreshCredential,
    this.onDeleteCredential,
    this.scrollBeyondBoundsCallback,
    this.short = false,
  })  : credentialInfo = credential.info,
        attributes = credential.attributes,
        expiryDate = credential.expires,
        cardTheme = IrmaCardTheme.fromCredentialInfo(credential.info);

  IrmaCard.fromRemovedCredential({
    RemovedCredential credential,
    this.scrollBeyondBoundsCallback,
  })  : credentialInfo = credential.info,
        attributes = credential.attributes,
        cardTheme = IrmaCardTheme.fromCredentialInfo(credential.info),
        short = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
      decoration: BoxDecoration(
        color: cardTheme.backgroundGradientStart,
        gradient: LinearGradient(
          colors: [
            cardTheme.backgroundGradientStart,
            cardTheme.backgroundGradientEnd,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(
          width: 1.0,
          color: cardTheme.backgroundGradientEnd,
        ),
        borderRadius: const BorderRadius.all(
          _borderRadius,
        ),
        boxShadow: const [
          BoxShadow(
            color: _transparentBlack,
            blurRadius: _blurRadius,
            offset: Offset(
              0.0,
              2.0,
            ),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              top: IrmaTheme.of(context).smallSpacing,
              left: IrmaTheme.of(context).defaultSpacing,
              bottom: 0,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    getTranslation(credentialInfo.credentialType.name),
                    style: Theme.of(context).textTheme.subhead.copyWith(
                          color: cardTheme.foregroundColor,
                        ),
                  ),
                ),
                CardMenu(
                  cardTheme: cardTheme,
                  onRefreshCredential: onRefreshCredential,
                  onDeleteCredential: onDeleteCredential,
                )
              ],
            ),
          ),
          Container(
            child: Column(
              children: [
                CardAttributes(
                  attributes: attributes,
                  irmaCardTheme: cardTheme,
                  scrollOverflowCallback: scrollBeyondBoundsCallback,
                  short: short,
                ),
                CardFooter(
                  credentialInfo: credentialInfo,
                  expiryDate: expiryDate,
                  irmaCardTheme: cardTheme,
                  scrollOverflowCallback: scrollBeyondBoundsCallback,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
