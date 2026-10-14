import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";

class _YiviProgressIndicatorElement extends StatelessWidget {
  final bool isActive;

  const _YiviProgressIndicatorElement({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    const double size = 8;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? theme.primary : theme.tertiary,
        borderRadius: BorderRadius.circular(20),
      ),
      height: size,
      width: isActive ? size * 3 : size,
    );
  }
}

class YiviProgressIndicator extends StatelessWidget {
  final int stepIndex;
  final int stepCount;

  /// Centres the dots instead of starting them at the left.
  final bool centered;

  const YiviProgressIndicator({
    required this.stepIndex,
    required this.stepCount,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: centered
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: List.generate(
        stepCount,
        (int index) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _YiviProgressIndicatorElement(isActive: index == stepIndex),
        ),
        growable: false,
      ),
    );
  }
}
