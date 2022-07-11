import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../theme/theme.dart';
import 'irma_step_indicator.dart';

class IrmaStepper extends StatelessWidget {
  final List<Widget> children;
  final int? currentIndex;

  const IrmaStepper({
    required this.children,
    this.currentIndex,
  });

  Widget _buildItem(IrmaThemeData theme, int index) {
    Widget child = children[index];

    // If this child has yet to be completed
    // wrap it in a color filter to make it look greyed out.
    if (currentIndex != null && index > currentIndex!) {
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
              // If this item is not active or currentIndex is null
              // show default outline indicator
              : currentIndex != null && currentIndex! < index
                  ? IrmaStepIndicatorStyle.outlined
                  //If item has already been completed show success indicator
                  : IrmaStepIndicatorStyle.success,
        ),
        padding: EdgeInsets.only(right: theme.smallSpacing),
      ),
      endChild: child,
      beforeLineStyle: LineStyle(
        thickness: 1,
        color: theme.themeData.colorScheme.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return ListView.builder(
      shrinkWrap: true,
      itemCount: children.length,
      itemBuilder: (_, index) => _buildItem(theme, index),
    );
  }
}
