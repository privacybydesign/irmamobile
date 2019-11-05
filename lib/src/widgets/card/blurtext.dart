import 'package:flutter/material.dart';

class BlurText extends StatelessWidget {
  final String text;
  final Color color;
  final bool isTextBlurred;

  BlurText(this.text, this.color, this.isTextBlurred);

  Widget build(BuildContext context) {
    return isTextBlurred
      ? Opacity(
      opacity: 0.8,
      child: Text(
        text,
        style: Theme.of(context)
          .textTheme
          .body1
          .copyWith(fontWeight: FontWeight.w700)
          .copyWith(color: Color(0x00ffffff))
          .copyWith(shadows: [
          Shadow(
            blurRadius: 7.0,
            color: color,
          ),
          Shadow(
            blurRadius: 15.0,
            color: color,
          ),
          Shadow(
            blurRadius: 20.0,
            color: color,
          ),
        ]),
      ),
    )
      : Text(text,
      style: Theme.of(context).textTheme.body1.copyWith(fontWeight: FontWeight.w700).copyWith(color: color));
  }
}
