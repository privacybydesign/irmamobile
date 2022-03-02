// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

void startDesignTypography(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) {
      return DesignTypography();
    }),
  );
}

class DesignTypography extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IrmaAppBar(
        title: Text("Typography"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              _buildFontExample(context, "H1 (Display 4)", IrmaTheme.of(context).textTheme.headline1),
              _buildFontExample(context, "H2 (Display 3)", IrmaTheme.of(context).textTheme.headline2),
              _buildFontExample(context, "H3 (Display 2)", IrmaTheme.of(context).textTheme.headline3),
              _buildFontExample(context, "H4 (Display 1)", IrmaTheme.of(context).textTheme.headline4),
              _buildFontExample(context, "BodyText1", IrmaTheme.of(context).textTheme.bodyText1),
              _buildFontExample(context, "BodyText2", IrmaTheme.of(context).textTheme.bodyText1),
              _buildFontExample(context, "hyperlink default", IrmaTheme.of(context).hyperlinkTextStyle),
              _buildFontExample(context, "Subtitle 1", IrmaTheme.of(context).textTheme.subtitle1),
              _buildFontExample(context, "Subtitle 2", IrmaTheme.of(context).textTheme.subtitle2),
              _buildFontExample(context, "Button", IrmaTheme.of(context).textTheme.button),
              _buildFontExample(context, "Caption", IrmaTheme.of(context).textTheme.caption),
              _buildFontExample(context, "Overline", IrmaTheme.of(context).textTheme.overline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontExample(BuildContext context, String name, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(name, style: style),
          Text(
            "Font-family: ${style.fontFamily} - Font-size: ${style.fontSize} - ${style.fontWeight.toString().replaceFirst("FontWeight.", "Font-weight: ")} - Line-height: ${style.height != null ? style.height.toStringAsFixed(2) : "Not specified"} - Color: #${style.color != null ? style.color.value.toRadixString(16) : "Not specified"}",
            style: IrmaTheme.of(context).textTheme.caption,
          ),
        ],
      ),
    );
  }
}
