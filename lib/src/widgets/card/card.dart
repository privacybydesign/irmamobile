// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/card/card_footer.dart';
import 'package:irmamobile/src/widgets/card/irma_card_theme.dart';
import 'package:irmamobile/src/widgets/card/models/card_expiry_date.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

import 'card_attributes.dart';
import 'card_menu.dart';

class IrmaCard extends StatelessWidget {
  static const _borderRadius = Radius.circular(15.0);
  static const _transparentBlack = Color(0x77000000);
  static const _blurRadius = 4.0;

  final CredentialInfo credentialInfo;
  final Attributes attributes;
  final bool revoked;
  final CardExpiryDate expiryDate; // Can be null

  final Function() onRefreshCredential;
  final Function() onDeleteCredential;

  final void Function(double) scrollBeyondBoundsCallback;

  final IrmaCardTheme cardTheme;
  final bool showWarnings;
  // If true the card expands to the size it needs and lets the parent handle the scrolling.
  final bool expanded;

  IrmaCard.fromCredential({
    Credential credential,
    this.onRefreshCredential,
    this.onDeleteCredential,
    this.scrollBeyondBoundsCallback,
    this.expanded = false,
    this.showWarnings = true,
  })  : credentialInfo = credential.info,
        attributes = credential.attributes,
        revoked = credential.revoked,
        expiryDate = CardExpiryDate(credential.expires),
        cardTheme = IrmaCardTheme.fromCredentialInfo(credential.info);

  IrmaCard.fromRemovedCredential({
    RemovedCredential credential,
    this.scrollBeyondBoundsCallback,
  })  : credentialInfo = credential.info,
        attributes = credential.attributes,
        cardTheme = IrmaCardTheme.fromCredentialInfo(credential.info),
        revoked = false,
        expanded = true,
        expiryDate = null,
        showWarnings = false,
        onRefreshCredential = null,
        onDeleteCredential = null;

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return IrmaDialog(
          title: FlutterI18n.translate(context, 'card.delete_title'),
          content: FlutterI18n.translate(context, 'card.delete_content'),
          child: Wrap(
            direction: Axis.horizontal,
            verticalDirection: VerticalDirection.up,
            alignment: WrapAlignment.spaceEvenly,
            children: <Widget>[
              IrmaTextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                minWidth: 0.0,
                label: 'card.delete_deny',
              ),
              IrmaButton(
                size: IrmaButtonSize.small,
                minWidth: 0.0,
                onPressed: () {
                  Navigator.of(context).pop();
                  onDeleteCredential();
                },
                label: 'card.delete_confirm',
              ),
            ],
          ),
        );
      },
    );
  }

  Function() _onDeleteCredentialHandler(BuildContext context) {
    if (onDeleteCredential == null) return null;
    return () => _showDeleteDialog(context);
  }

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
                    CardMenu(
                      cardTheme: cardTheme,
                      onRefreshCredential: onRefreshCredential,
                      onDeleteCredential: _onDeleteCredentialHandler(context),
                      allGood: !revoked && (expiryDate == null || !expiryDate.expired && !expiryDate.expiresSoon),
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
                      expanded: expanded,
                      showWarnings: showWarnings,
                      expiryDate: expiryDate,
                      revoked: revoked,
                      color: cardTheme.backgroundGradientEnd,
                      onRefreshCredential: onRefreshCredential,
                      onDeleteCredential: _onDeleteCredentialHandler(context),
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
