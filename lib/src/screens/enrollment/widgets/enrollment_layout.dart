import 'package:flutter/material.dart';

class EnrollmentLayout extends StatelessWidget {
  final Widget graphic;
  final Widget instruction;

  const EnrollmentLayout({
    required this.graphic,
    required this.instruction,
  });

  Row _buildLandscapeLayout() => Row(
        children: [
          Flexible(
            flex: 4,
            child: graphic,
          ),
          Flexible(
            flex: 5,
            child: instruction,
          )
        ],
      );

  Column _buildPortraitLayout({
    bool isSmallScreen = false,
  }) =>
      Column(
        children: [
          Expanded(
            child: graphic,
          ),
          Expanded(
            child: instruction,
          )
        ],
      );

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isSmallScreen = MediaQuery.of(context).size.height < 670;

    return isLandscape
        ? _buildLandscapeLayout()
        : _buildPortraitLayout(
            isSmallScreen: isSmallScreen,
          );
  }
}
