import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../theme/theme.dart';
import 'irma_step_indicator.dart';

class IrmaStepper extends StatelessWidget {
  final List<Widget> children;
  final int currentIndex;

  const IrmaStepper({
    required this.children,
    required this.currentIndex,
  });

  Widget _buildItem(IrmaThemeData theme, int index) {
    Widget child = children[index];

    // If this child has yet to be completed
    // wrap it in a color filter to make it look greyed out.
    if (index > currentIndex) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.white.withOpacity(0.5),
          BlendMode.modulate,
        ),
        child: child,
      );
    }

    return TimelineTile(
      indicatorStyle: IndicatorStyle(
        indicator: IrmaStepIndicator(
          step: index + 1,
          //If item is current show filled indicator
          style: currentIndex == index
              ? IrmaStepIndicatorStyle.filled
              //If item has already been completed show success indicator
              : currentIndex > index
                  ? IrmaStepIndicatorStyle.success
                  //Else show outlined indicator
                  : IrmaStepIndicatorStyle.outlined,
        ),
        padding: EdgeInsets.all(theme.smallSpacing),
      ),
      endChild: child,
      beforeLineStyle: LineStyle(
        thickness: 1,
        color: theme.themeData.colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return ScrollablePositionedList.builder(
      shrinkWrap: true,
      itemCount: children.length,
      itemBuilder: (_, index) => _buildItem(theme, index),
    );
  }
}
