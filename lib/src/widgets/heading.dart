// This Heading is used to make headlines more accessible.
// It wraps a Text() widget with a Semantics() widget to indicate that
// the text is a heading. VoiceOver will now append the word "heading"
// when it reads this text. One can choose the style of the heading by
// providing a TextStyle. If no TextStyle is provided, a default TextStyle is
// used.

import 'package:flutter/material.dart';

class Heading extends StatelessWidget {
  final String title;
  final TextStyle style;
  final TextAlign textAlign;
  const Heading(this.title, {this.style, this.textAlign});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: style ?? Theme.of(context).textTheme.headline3,
        textAlign: textAlign ?? TextAlign.left,
      ),
    );
  }
}
