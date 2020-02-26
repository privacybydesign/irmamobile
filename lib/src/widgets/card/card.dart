import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/card/irma_card_theme.dart';

import 'card_attributes.dart';
import 'card_menu.dart';

class IrmaCard extends StatelessWidget {
  static const _borderRadius = Radius.circular(15.0);
  static const _transparentBlack = Color(0x77000000);
  static const _blurRadius = 4.0;

  final String lang = 'nl';

  final Credential credential;
  final Function() onRefreshCredential;
  final Function() onDeleteCredential;

  final void Function(double) scrollBeyondBoundsCallback;
  final bool isDeleted;

  final IrmaCardTheme cardTheme;

  IrmaCard({
    this.credential,
    this.onRefreshCredential,
    this.onDeleteCredential,
    this.scrollBeyondBoundsCallback,
    this.isDeleted = false,
  }) : cardTheme = IrmaCardTheme.fromCredentialType(credential);

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
                    getTranslation(credential.credentialType.name),
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
            child: CardAttributes(
              credential: credential,
              irmaCardTheme: cardTheme,
              scrollOverflowCallback: scrollBeyondBoundsCallback,
            ),
          ),
        ],
      ),
    );
  }
}
