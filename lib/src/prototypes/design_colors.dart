// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

void startDesignColors(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) {
      return DesignColors();
    }),
  );
}

class DesignColors extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IrmaAppBar(
        title: Text("Colors"),
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            _buildColorList(context, "Primary colors", {
              "primaryBlue": IrmaTheme.of(context).primaryBlue,
              "primaryDark": IrmaTheme.of(context).primaryDark,
              "primaryLight": IrmaTheme.of(context).primaryLight,
            }),
            _buildColorList(context, "Grayscale", {
              "white": Colors.white,
              "grayscale90": IrmaTheme.of(context).grayscale90,
              "grayscale80": IrmaTheme.of(context).grayscale80,
              "grayscale60": IrmaTheme.of(context).grayscale60,
              "grayscale40": IrmaTheme.of(context).grayscale40,
              "black": Colors.black,
            }),
            _buildColorList(context, "Supplementary colors", {
              "cardRed": IrmaTheme.of(context).cardRed,
              "cardBlue": IrmaTheme.of(context).cardBlue,
              "cardOrange": IrmaTheme.of(context).cardOrange,
              "cardGreen": IrmaTheme.of(context).cardGreen,
            }),
            _buildColorList(context, "Support colors", {
              "interactionValid": IrmaTheme.of(context).interactionValid,
              "interactionInvalid": IrmaTheme.of(context).interactionInvalid,
              "interactionAlert": IrmaTheme.of(context).interactionAlert,
              "interactionInformation": IrmaTheme.of(context).interactionInformation,
            }),
            _buildColorList(context, "Overlay", {
              "overlay50": IrmaTheme.of(context).overlay50,
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildColorList(BuildContext context, String name, Map<String, Color> colors) {
    final colorWidgets = colors.entries
        .map<Widget>(
          (entry) => _buildColorWidget(context, entry.key, entry.value),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(name, style: IrmaTheme.of(context).textTheme.display3),
        ),
        Wrap(children: colorWidgets),
      ],
    );
  }

  Widget _buildColorWidget(BuildContext context, String name, Color color) {
    Border border;
    if (color.computeLuminance() > 0.6) {
      border = Border.all();
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color,
              border: border,
            ),
          ),
          Text(name, style: IrmaTheme.of(context).textTheme.body1),
          Text("#${color.value.toRadixString(16)}", style: IrmaTheme.of(context).textTheme.caption),
        ],
      ),
    );
  }
}
