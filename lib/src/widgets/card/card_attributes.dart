import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/card/irma_card_theme.dart';

// final Image photo;
// photo = Image.memory(credential.decodeImage());

class CardAttributes extends StatelessWidget {
  final _lang = ui.window.locale.languageCode;
  final _indent = 100.0;
  final _maxHeight = 300.0;
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

    return Column(
      children: [
        LimitedBox(
          maxHeight: _maxHeight,
          child: Container(
            padding: EdgeInsets.only(
              top: IrmaTheme.of(context).defaultSpacing,
              right: IrmaTheme.of(context).smallSpacing,
            ),
            constraints: BoxConstraints(
              minHeight: _minHeight,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (false) ...[
                  _buildPhoto(context),
                ],
                Expanded(
                  child: Scrollbar(
                    child: ListView(
                      shrinkWrap: true,
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(left: IrmaTheme.of(context).defaultSpacing),
                      children: [
                        ..._buildAttributes(context, body1Theme),
                        SizedBox(
                          height: IrmaTheme.of(context).defaultSpacing,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Column(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1.0, color: Color(0x77000000)),
                  bottom: BorderSide(width: 1.0, color: Color(0x77FFFFFF)),
                ),
              ),
            ),
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
    if (false) {
      return Container();
    }

    return Padding(
      padding: EdgeInsets.only(top: 6, bottom: IrmaTheme.of(context).smallSpacing),
      child: Container(
        width: 90,
        height: 120,
        color: const Color(0xff777777),
        child: Container(), // TODO: Here should be the photo
      ),
    );
  }

  List<Widget> _buildAttributes(BuildContext context, TextStyle body1Theme) {
    final Attributes attributes = credential.attributes;

    return attributes.sortedAttributeTypes
        .expand(
          (attributeType) => [
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
          ],
        )
        .toList();
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
