import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/card/irma_card_theme.dart';

class CardAttributes extends StatelessWidget {
  final _lang = ui.window.locale.languageCode;

  final _indent = 100.0;
  final _minHeight = 120.0; // TODO: perfect aspect ratio

  final Credential credential;
  final IrmaCardTheme irmaCardTheme;
  final void Function(double) scrollOverflowCallback;

  CardAttributes({
    this.credential,
    this.irmaCardTheme,
    this.scrollOverflowCallback,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle body1Theme = IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.foregroundColor);

    final ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.offset < 0) {
        scrollOverflowCallback(-scrollController.offset);
      }
    });

    // Make sure the card uses a good maximum height (uses all available space)
    // TODO: Remove weird hardcoded values and replace them with something that makes sense
    // These hardcoded values were tested with smallest screen and biggest screen and one in between

    double height = MediaQuery.of(context).size.height;
    var padding = MediaQuery.of(context).padding;
    double _maxHeight = (height - padding.top - kToolbarHeight) - ((height / 8) + 200);

    return Column(
      children: [
        LimitedBox(
          maxHeight: _maxHeight,
          child: Container(
            padding: EdgeInsets.only(
              top: IrmaTheme.of(context).defaultSpacing,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildPhoto(context),
                Expanded(
                  child: Stack(
                    alignment: AlignmentDirectional.bottomCenter,
                    children: <Widget>[
                      Container(
                        constraints: BoxConstraints(
                          minHeight: _minHeight,
                        ),
                        padding: EdgeInsets.only(
                          right: IrmaTheme.of(context).smallSpacing,
                        ),
                        child: Scrollbar(
                          child: ListView(
                            shrinkWrap: true,
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.only(left: IrmaTheme.of(context).defaultSpacing,
                            children: [
                              ..._buildAttributes(context, body1Theme),
                              SizedBox(
                                height: IrmaTheme.of(context).defaultSpacing,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        child: Container(
                          height: 8.0,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(width: 1.0, color: irmaCardTheme.backgroundGradientEnd),
                            ),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0x00000000),
                                Color(0x33000000),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Column(
          children: <Widget>[
            Container(
              color: const Color(0x11FFFFFF),
              child: Column(
                children: <Widget>[
                  _buildIssuer(context, body1Theme),
                  _buildExpiration(context, body1Theme),
                ],
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildPhoto(BuildContext context) {
    if (credential.attributes.portraitPhoto == null) {
      return Container(height: 0);
    }

    return Padding(
      padding: EdgeInsets.only(top: 6, bottom: IrmaTheme.of(context).smallSpacing),
      child: Container(
        width: 90,
        height: 120,
        color: const Color(0xff777777),
        child: credential.attributes.portraitPhoto,
      ),
    );
  }

  List<Widget> _buildAttributes(BuildContext context, TextStyle body1Theme) {
    final Attributes attributes = credential.attributes;

    return attributes.sortedAttributeTypes.expand<Widget>(
      (attributeType) {
        if (attributeType.displayHint == "portraitPhoto") {
          return [];
        }

        return [
          Opacity(
            opacity: 0.8,
            child: Text(
              attributeType.name[_lang],
              style: body1Theme.copyWith(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            attributes[attributeType][_lang],
            style: IrmaTheme.of(context).textTheme.body2.copyWith(color: irmaCardTheme.foregroundColor),
          ),
          SizedBox(
            height: IrmaTheme.of(context).smallSpacing,
          ),
        ];
      },
    ).toList();
  }

  Widget _buildIssuer(BuildContext context, TextStyle body1Theme) {
    return Padding(
      padding: EdgeInsets.only(
        top: IrmaTheme.of(context).smallSpacing,
        left: IrmaTheme.of(context).defaultSpacing,
        right: IrmaTheme.of(context).defaultSpacing,
      ),
      child: Row(
        children: [
          Container(
            width: _indent,
            child: Opacity(
              opacity: 0.8,
              child: Text(
                FlutterI18n.translate(context, 'wallet.issuer'),
                style: body1Theme.copyWith(fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: Text(
              credential.issuer.name[_lang],
              style: body1Theme.copyWith(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiration(BuildContext context, TextStyle body1Theme) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: IrmaTheme.of(context).smallSpacing,
        left: IrmaTheme.of(context).defaultSpacing,
        right: IrmaTheme.of(context).defaultSpacing,
      ),
      child: Row(
        children: [
          Container(
            width: _indent,
            child: Opacity(
              opacity: 0.8,
              child: Text(
                FlutterI18n.translate(context, 'wallet.expiration'),
                style: body1Theme.copyWith(fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: Text(
              _printableDate(credential.expires, _lang),
              style: body1Theme.copyWith(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _printableDate(DateTime date, String lang) {
    return DateFormat.yMMMMd(lang).format(date);
  }
}
