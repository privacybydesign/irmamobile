import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/card/irma_card_theme.dart';

class CardFooter extends StatelessWidget {
  final CredentialInfo credentialInfo;
  final DateTime expiryDate;
  final bool revoked;

  final IrmaCardTheme irmaCardTheme;
  final void Function(double) scrollOverflowCallback;

  bool get expired => expiryDate.isBefore(DateTime.now());

  final double _indent = 110;

  const CardFooter({
    this.credentialInfo,
    this.revoked,
    this.expiryDate,
    this.irmaCardTheme,
    this.scrollOverflowCallback,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle body1Theme = IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.foregroundColor);
    final lang = FlutterI18n.currentLocale(context).languageCode;

    final ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.offset < 0) {
        scrollOverflowCallback(-scrollController.offset);
      }
    });

    return Container(
      color: const Color(0x11FFFFFF),
      child: Padding(
        padding: EdgeInsets.only(
          top: IrmaTheme.of(context).smallSpacing,
          left: IrmaTheme.of(context).defaultSpacing,
          right: IrmaTheme.of(context).defaultSpacing,
          bottom: IrmaTheme.of(context).smallSpacing,
        ),
        child: Column(
          children: <Widget>[
            _buildIssuer(context, body1Theme, lang),
            if (!revoked && expiryDate != null) _buildExpiration(context, body1Theme, lang),
            if (revoked) _buildRevoked(context, body1Theme),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuer(BuildContext context, TextStyle body1Theme, String lang) {
    return Row(
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
            credentialInfo.issuer.name[lang],
            style: body1Theme.copyWith(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRevoked(BuildContext context, TextStyle body1Theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          // width: _indent,
          child: Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: Opacity(
              opacity: 0.8,
              child: Text(
                FlutterI18n.translate(context, 'wallet.not_valid'),
                style: body1Theme.copyWith(fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiration(BuildContext context, TextStyle body1Theme, String lang) {
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
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
                _printableDate(expiryDate, lang),
                style: body1Theme.copyWith(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _printableDate(DateTime date, String lang) {
    return DateFormat.yMMMMd(lang).format(date);
  }
}
