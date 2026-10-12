import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";

// The design draws the box at 22 px. Material paints it at 18 px, so it is
// scaled up inside the smallest target size WCAG 2.2 allows (2.5.8).
const double _slotSize = 24;
const double _boxScale = 22 / Checkbox.width;

// The label starts 12 px after the box. The slot already leaves 1 px.
const double _labelGap = 10;

// The border is 2 px once scaled up with the box.
const double _borderWidth = 2 / _boxScale;

/// A checkbox the size of the onboarding v2 design, with the gap to its label.
class OnboardingCheckbox extends StatelessWidget {
  final Key? checkboxKey;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const OnboardingCheckbox({
    super.key,
    this.checkboxKey,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: _labelGap),
      child: SizedBox.square(
        dimension: _slotSize,
        child: Transform.scale(
          scale: _boxScale,
          child: Checkbox(
            key: checkboxKey,
            value: value,
            onChanged: onChanged,
            activeColor: theme.themeData.colorScheme.secondary,
            side: WidgetStateBorderSide.resolveWith(
              (states) => BorderSide(
                width: _borderWidth,
                color: states.contains(WidgetState.selected)
                    ? Colors.transparent
                    : theme.neutralDark,
              ),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          ),
        ),
      ),
    );
  }
}
