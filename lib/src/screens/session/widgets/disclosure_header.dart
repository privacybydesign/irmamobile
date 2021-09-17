// This code is not null safe yet.
// @dart=2.11

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_message.dart';
import 'package:irmamobile/src/widgets/irma_quote.dart';
import 'package:irmamobile/src/widgets/translated_rich_text.dart';

class DisclosureHeader extends StatelessWidget {
  final SessionState session;

  static const _maxLogoSize = Size.square(85);
  static const _badgePadding = EdgeInsets.only(right: 2);

  const DisclosureHeader({Key key, this.session}) : super(key: key);

  TextSpan _buildVerifiedName(BuildContext context, BoxConstraints constraints, String verifiedName) {
    final style = IrmaTheme.of(context).highlightedTextStyle;

    // Split off the first word (so the characters before the first 'space').
    final endFirstWord = verifiedName.indexOf(' ');
    final firstWord = endFirstWord < 0 ? verifiedName : verifiedName.substring(0, endFirstWord);
    final otherWords = endFirstWord < 0 ? '' : verifiedName.substring(endFirstWord);

    // Widget for badge check icon.
    final badgeIcon = WidgetSpan(
      child: Padding(
        padding: _badgePadding,
        child: SvgPicture.asset(
          'assets/disclosure/badge-check.svg',
          color: style.color,
        ),
      ),
    );

    // Make a text span, only including the badge check icon and the verifiedName's first word.
    final firstWordSpan = TextSpan(
      style: style,
      children: [
        badgeIcon,
        TextSpan(text: firstWord),
      ],
    );

    // Calculate whether the badge check icon and the first word fit on one line.
    final tp = TextPainter(
      text: firstWordSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
    );
    // Flutter does not know the size of the icon yet, so we use a placeholder of the same size.
    tp.setPlaceholderDimensions([
      PlaceholderDimensions(
        size: Size(
          tp.preferredLineHeight + _badgePadding.horizontal,
          tp.preferredLineHeight + _badgePadding.vertical,
        ),
        alignment: PlaceholderAlignment.bottom,
      ),
    ]);
    tp.layout(maxWidth: constraints.maxWidth);

    // If it does not fit, we are dealing with a very long first word. This will hardly ever happen,
    // so in this case we let TextSpan figure out a solution for us.
    // If it does fit, we make sure line breaks cannot be placed between the icon and the first word.
    return TextSpan(
      style: style,
      children: tp.didExceedMaxLines
          ? [
              badgeIcon,
              TextSpan(text: verifiedName),
            ]
          : [
              // The Text.rich that uses this TextSpan determines the textScaleFactor, so we should prevent additional scaling.
              WidgetSpan(
                child: Text.rich(firstWordSpan, softWrap: false, textScaleFactor: 1.0),
              ),
              TextSpan(text: otherWords),
            ],
    );
  }

  Widget _buildHeaderText(BuildContext context) {
    final sessionType = session.isSignatureSession ? 'signing' : 'disclosure';
    final textKey = 'disclosure.$sessionType${session.clientReturnURL?.isPhoneNumber ?? false ? '_call' : ''}_header';

    final serverName = session.serverName.name.translate(FlutterI18n.currentLocale(context).languageCode);
    final phoneNumber = session.clientReturnURL?.phoneNumber ?? '';

    return LayoutBuilder(
      builder: (context, constraints) => TranslatedRichText(
        textKey,
        style: Theme.of(context).textTheme.bodyText2,
        translationParams: {
          'otherParty': session.serverName.unverified
              ? TextSpan(text: serverName, style: IrmaTheme.of(context).textTheme.bodyText1)
              : _buildVerifiedName(context, constraints, serverName),
          'phoneNumber': TextSpan(
            text: phoneNumber,
            style: IrmaTheme.of(context).textTheme.bodyText1,
          ),
        },
        semanticsParams: {
          'otherParty': serverName,
          'phoneNumber': phoneNumber,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoFile = File(session.serverName.logoPath ?? '');
    return Semantics(
      explicitChildNodes: true,
      child: Column(
        children: <Widget>[
          if (!session.satisfiable)
            Padding(
              padding: EdgeInsets.only(bottom: IrmaTheme.of(context).mediumSpacing),
              child: const IrmaMessage(
                'disclosure.unsatisfiable_title',
                'disclosure.unsatisfiable_message',
                type: IrmaMessageType.info,
              ),
            ),
          Row(
            children: [
              if (logoFile.existsSync())
                Container(
                  margin: EdgeInsets.only(right: IrmaTheme.of(context).defaultSpacing),
                  constraints: BoxConstraints.tight(_maxLogoSize),
                  child: Image.file(
                    logoFile,
                    semanticLabel: FlutterI18n.translate(
                      context,
                      'disclosure.logo_semantic',
                      translationParams: {
                        'otherParty': session.serverName.name.translate(FlutterI18n.currentLocale(context).languageCode)
                      },
                    ),
                  ),
                ),
              Expanded(child: _buildHeaderText(context)),
            ],
          ),
          if (session.isSignatureSession)
            Padding(
              padding: EdgeInsets.only(top: IrmaTheme.of(context).mediumSpacing),
              child: IrmaQuote(quote: session.signedMessage),
            ),
        ],
      ),
    );
  }
}
