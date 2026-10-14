import "package:material_ui/material_ui.dart";

/// An introduction step: the picture above the text and buttons, or next to
/// them when the space is wide and low (a phone in landscape).
class EnrollmentLayout extends StatelessWidget {
  final Widget hero;
  final Widget instruction;

  const EnrollmentLayout({required this.hero, required this.instruction});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wideAndLow =
            constraints.maxWidth > constraints.maxHeight &&
            constraints.maxHeight < 600;
        if (wideAndLow) {
          return Row(
            children: [
              Expanded(flex: 4, child: Center(child: hero)),
              Expanded(flex: 5, child: Center(child: instruction)),
            ],
          );
        }
        // The text takes what it needs, up to 4/9 of the height; on a small
        // phone it scrolls rather than squeezing the picture away.
        return Column(
          children: [
            Expanded(flex: 5, child: Center(child: hero)),
            Flexible(flex: 4, child: instruction),
          ],
        );
      },
    );
  }
}
