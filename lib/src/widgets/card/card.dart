import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
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

  final CredentialInfo credentialInfo;
  final Attributes attributes;
  final bool revoked;
  final DateTime expiryDate;

  bool get expired => expiryDate.isBefore(DateTime.now());
  int get validDays => expiryDate.difference(DateTime.now()).inDays;
  bool get expiresSoon => (validDays <= 77);

  final Function() onRefreshCredential;
  final Function() onDeleteCredential;

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
        revoked = credential.revoked,
        expiryDate = credential.expires,
        cardTheme = IrmaCardTheme.fromCredentialInfo(credential.info);

  IrmaCard.fromRemovedCredential({
    RemovedCredential credential,
    this.scrollBeyondBoundsCallback,
  })  : credentialInfo = credential.info,
        attributes = credential.attributes,
        cardTheme = IrmaCardTheme.fromCredentialInfo(credential.info),
        revoked = false,
        short = true,
        expiryDate = null,
        onRefreshCredential = null,
        onDeleteCredential = null;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
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
                    bottom: IrmaTheme.of(context).smallSpacing),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        getTranslation(context, credentialInfo.credentialType.name),
                        style: Theme.of(context).textTheme.subhead.copyWith(
                              color: cardTheme.foregroundColor,
                            ),
                      ),
                    ),
                    if (!revoked && !expired && !expiresSoon)
                      CardMenu(
                        cardTheme: cardTheme,
                        onRefreshCredential: onRefreshCredential,
                        onDeleteCredential: onDeleteCredential,
                      )
                    else
                      Padding(
                        padding: EdgeInsets.only(right: IrmaTheme.of(context).smallSpacing),
                        child: Icon(
                          IrmaIcons.warning,
                          size: 16.0,
                          color: cardTheme.foregroundColor,
                        ),
                      ),
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
                      expired: expired,
                      expiresSoon: expiresSoon,
                      validDays: validDays,
                      revoked: revoked,
                      color: cardTheme.backgroundGradientEnd,
                      onRefreshCredential: onRefreshCredential,
                    ),
                    CardFooter(
                      credentialInfo: credentialInfo,
                      expiryDate: expiryDate,
                      revoked: revoked,
                      irmaCardTheme: cardTheme,
                      scrollOverflowCallback: scrollBeyondBoundsCallback,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
