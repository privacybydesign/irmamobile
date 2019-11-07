import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';

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
      appBar: AppBar(
        title: Text("Typography"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              _buildFontExample(context, "H1 (Display 4)", IrmaTheme.of(context).textTheme.display4),
              _buildFontExample(context, "H2 (Display 3)", IrmaTheme.of(context).textTheme.display3),
              _buildFontExample(context, "H3 (Display 2)", IrmaTheme.of(context).textTheme.display2),
              _buildFontExample(context, "H4 (Display 1)", IrmaTheme.of(context).textTheme.display1),
              _buildFontExample(context, "p (Body 1)", IrmaTheme.of(context).textTheme.body1),
              _buildFontExample(context, "p-bold (Body 2)", IrmaTheme.of(context).textTheme.body2),
              _buildFontExample(context, "hyperlink default", IrmaTheme.of(context).hyperlinkTextStyle),
              _buildFontExample(context, "hyperlink visited", IrmaTheme.of(context).hyperlinkVisitedTextStyle),
              _buildFontExample(context, "Subhead", IrmaTheme.of(context).textTheme.subhead),
              _buildFontExample(context, "Subtitle", IrmaTheme.of(context).textTheme.subtitle),
              _buildFontExample(context, "Button", IrmaTheme.of(context).textTheme.button),
              _buildFontExample(context, "Caption", IrmaTheme.of(context).textTheme.caption),
              _buildFontExample(context, "Overline", IrmaTheme.of(context).textTheme.overline),
              _buildFontExample(context, "Issuer (on cards)", IrmaTheme.of(context).issuerNameTextStyle),
              _buildFontExample(context, "New card button", IrmaTheme.of(context).newCardButtonTextStyle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontExample(BuildContext context, String name, TextStyle style) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(name, style: style),
          Text(
            "Font-family: ${style.fontFamily} - Font-size: ${style.fontSize} - ${style.fontWeight.toString().replaceFirst("FontWeight.", "Font-weight: ")} - Line-height: ${style.height.toStringAsFixed(2)}× - Color: #${style.color.value.toRadixString(16)}",
            style: IrmaTheme.of(context).textTheme.caption,
          ),
        ],
      ),
    );
  }
}
