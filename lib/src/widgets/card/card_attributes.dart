import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/card/irma_card_theme.dart';

// ignore: must_be_immutable
class CardAttributes extends StatelessWidget {
  String _lang;

  final Attributes attributes;
  final IrmaCardTheme irmaCardTheme;
  final void Function(double) scrollOverflowCallback;
  final bool short;

  CardAttributes({
    this.attributes,
    this.irmaCardTheme,
    this.scrollOverflowCallback,
    this.short = false,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle body1Theme = IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.foregroundColor);
    _lang = FlutterI18n.currentLocale(context).languageCode;

    final ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.offset < 0) {
        scrollOverflowCallback(-scrollController.offset);
      }
    });

    // Make sure the card uses a good maximum height (uses all available space)
    // TODO: Remove weird hardcoded values and replace them with something that makes sense
    // These hardcoded values were tested with smallest screen and biggest screen and one in between

    final size = MediaQuery.of(context).size;

    final height = size.height;
    final width = size.width;
    final padding = MediaQuery.of(context).padding;
    const creditCardAspectRatio = 5398 / 8560;
    final _minHeight = (width - IrmaTheme.of(context).smallSpacing * 2) * creditCardAspectRatio - 90;
    final double _maxHeight = (height - padding.top - kToolbarHeight) - ((height / 8) + (short ? 260 : 210));

    return LimitedBox(
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) {
    if (attributes.portraitPhoto == null) {
      return Container(height: 0);
    }

    return Padding(
      padding: EdgeInsets.only(
        top: 6,
        bottom: IrmaTheme.of(context).smallSpacing,
        left: IrmaTheme.of(context).defaultSpacing,
      ),
      child: Container(
        width: 90,
        height: 120,
        color: const Color(0xff777777),
        child: attributes.portraitPhoto,
      ),
    );
  }

  List<Widget> _buildAttributes(BuildContext context, TextStyle body1Theme) {
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
            // Empty attributes are rendered by displaying a dash
            attributes[attributeType] is TextValue ? (attributes[attributeType] as TextValue).translated[_lang] : "-",
            style: IrmaTheme.of(context).textTheme.body2.copyWith(color: irmaCardTheme.foregroundColor),
          ),
          SizedBox(
            height: IrmaTheme.of(context).smallSpacing,
          ),
        ];
      },
    ).toList();
  }
}
