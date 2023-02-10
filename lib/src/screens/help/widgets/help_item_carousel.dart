import 'package:flutter/material.dart';

import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/theme.dart';

import 'illustrator.dart';

class HelpCarousel extends StatefulWidget {
  final List<HelpCarouselItem> items;

  const HelpCarousel({required this.items});

  @override
  State<HelpCarousel> createState() => _HelpCarouselState();
}

class _HelpCarouselState extends State<HelpCarousel> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: IrmaTheme.of(context).smallSpacing,
        ),
        Illustrator(
          imageSet: [
            for (var item in widget.items)
              Center(
                child: SizedBox(
                  child: item.imagePath.endsWith('svg')
                      ? SvgPicture.asset(
                          item.imagePath,
                          excludeFromSemantics: true,
                        )
                      : Image.asset(
                          item.imagePath,
                          excludeFromSemantics: true,
                        ),
                ),
              )
          ],
          textSet: [
            for (var item in widget.items) FlutterI18n.translate(context, item.translationKey),
          ],
          width: 300.0,
          height: 220.0,
        ),
      ],
    );
  }
}

class HelpCarouselItem {
  final String imagePath;
  final String translationKey;

  HelpCarouselItem(this.imagePath, this.translationKey);
}
