import "package:flutter/material.dart";
import "package:timeline_tile/timeline_tile.dart";

import "../theme/theme.dart";
import "irma_step_indicator.dart";

class IrmaStepper extends StatelessWidget {
  final List<Widget> children;
  final int? currentIndex;

  const IrmaStepper({required this.children, this.currentIndex});

  Widget _buildItem(BuildContext context, int index) => TimelineTile(
    isFirst: index == 0,
    isLast: index == children.length - 1,
    indicatorStyle: IndicatorStyle(
      height: 24,
      width: 24,
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
      padding: EdgeInsets.only(
        right: context.yivi.spacing.small,
        top: context.yivi.spacing.tiny,
        bottom: context.yivi.spacing.tiny,
      ),
    ),
    endChild: children[index],
    beforeLineStyle: LineStyle(thickness: 1, color: context.colors.secondary),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < children.length; i++) _buildItem(context, i),
      ],
    );
  }
}
