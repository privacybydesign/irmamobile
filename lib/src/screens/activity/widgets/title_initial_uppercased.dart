import 'package:flutter/material.dart';

class TitleInitialUpperCased extends StatelessWidget {
  final String title;
  const TitleInitialUpperCased(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.fitHeight,
        child: Text(
          title[0].toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF9A9EB4),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
