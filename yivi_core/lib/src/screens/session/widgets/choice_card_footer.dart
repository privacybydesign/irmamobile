import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
import "../../../widgets/translated_rich_text.dart";

const _bandColor = Color(0xFFF5F3F1);
const _bandBorderColor = Color(0xFFE3DDD9);
const _bandBorderWidth = 1.0;
const _bandRadius = Radius.circular(12);
// How far the band reaches up behind the card, so the card's rounded bottom
// corners show the band instead of the page.
const _bandOverlap = 12.0;
const _chevronSize = 18.0;

/// A share-screen card that is part of a choice, on top of a band that says
/// who certified the data. A tap on the band opens the options.
class ChoiceCardFooter extends StatelessWidget {
  final Widget card;
  final String issuerName;
  final VoidCallback onTap;

  const ChoiceCardFooter({
    super.key,
    required this.card,
    required this.issuerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    const side = BorderSide(color: _bandBorderColor, width: _bandBorderWidth);
    final padding = theme.smallSpacing + theme.tinySpacing;
    final textStyle = TextStyle(
      fontFamily: theme.secondaryFontFamily,
      fontSize: 14,
      height: 20 / 14,
      color: theme.neutralExtraDark,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _bandOverlap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _bandColor,
                  border: Border(left: side, right: side),
                ),
              ),
            ),
            card,
          ],
        ),
        Semantics(
          button: true,
          label: FlutterI18n.translate(
            context,
            "disclosure_permission.choice.certified_by",
            translationParams: {"issuer": issuerName},
          ),
          hint: FlutterI18n.translate(
            context,
            "disclosure_permission.change_choice",
          ),
          excludeSemantics: true,
          onTap: onTap,
          // The band has no top border: its top lies behind the card.
          child: DecoratedBox(
            key: const Key("choice_card_footer"),
            decoration: const BoxDecoration(
              color: _bandColor,
              border: Border(left: side, right: side, bottom: side),
              borderRadius: BorderRadius.vertical(bottom: _bandRadius),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.vertical(bottom: _bandRadius),
                child: Padding(
                  // A border takes no room in Flutter, so add its width.
                  padding: EdgeInsets.fromLTRB(
                    theme.defaultSpacing + _bandBorderWidth,
                    padding,
                    padding + _bandBorderWidth,
                    padding + _bandBorderWidth,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TranslatedRichText(
                          "disclosure_permission.choice.certified_by",
                          translationParams: {
                            "issuer": TextSpan(
                              text: issuerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          },
                          semanticsParams: {"issuer": issuerName},
                          style: textStyle,
                        ),
                      ),
                      SizedBox(width: theme.smallSpacing),
                      Icon(
                        Icons.chevron_right,
                        size: _chevronSize,
                        color: theme.neutralExtraDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
