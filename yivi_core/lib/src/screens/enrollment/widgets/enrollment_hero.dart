import "package:flutter/widgets.dart";
import "package:flutter_svg/svg.dart";
import "package:lottie/lottie.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";

class EnrollmentHero extends StatelessWidget {
  final String imagePath;

  EnrollmentHero(this.imagePath)
    : assert(imagePath.endsWith("svg") || imagePath.endsWith("json"));

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SafeArea(
      minimum: isLandscape
          ? EdgeInsets.symmetric(vertical: theme.defaultSpacing)
          : EdgeInsets.zero,
      child: imagePath.endsWith("json")
          ? Lottie.asset(
              imagePath,
              // Render at the composition's own frame rate instead of
              // forcing 60fps, which forces unnecessary interpolation work
              // on slower devices.
              frameRate: FrameRate.composition,
              // If the animation fails to load, show nothing instead of
              // crashing; this hero image is purely decorative.
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            )
          : SvgPicture.asset(imagePath, fit: BoxFit.contain),
    );
  }
}
