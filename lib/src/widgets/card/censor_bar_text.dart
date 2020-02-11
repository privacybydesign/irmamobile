import 'package:flutter/material.dart';

class CensorBarText extends StatelessWidget {
  final String data;
  final TextStyle style;
  final Color barColor;
  final bool isCensored;

  const CensorBarText(this.data, {this.style, this.isCensored = true, this.barColor = const Color(0xFF000000)});

  @override
  Widget build(BuildContext context) {
    if (!isCensored) {
      return Text(data, style: style);
    }

    return ExcludeSemantics(
      child: Opacity(
        opacity: 0.8,
        child: Text(
          data,
          style: style.copyWith(color: const Color(0x00ffffff)).copyWith(
            shadows: [
              Shadow(
                blurRadius: 7.0,
                color: barColor,
              ),
              Shadow(
                blurRadius: 15.0,
                color: barColor,
              ),
              Shadow(
                blurRadius: 20.0,
                color: barColor,
              ),
            ],
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
