import 'package:flutter/material.dart';

class EnrollmentLayout extends StatelessWidget {
  final Widget hero;
  final Widget instruction;

  const EnrollmentLayout({
    required this.hero,
    required this.instruction,
  });

  Row _buildLandscapeLayout() => Row(
        children: [
          Flexible(
            flex: 4,
            child: hero,
          ),
          Flexible(
            flex: 5,
            child: instruction,
          )
        ],
      );

  Column _buildPortraitLayout() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: hero,
          ),
          Expanded(
            child: instruction,
          )
        ],
      );

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout();
  }
}
