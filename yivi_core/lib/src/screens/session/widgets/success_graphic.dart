import "dart:math";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../../package_name.dart";
import "../../../data/feature_flags.dart";
import "../../../providers/feature_flag_provider.dart";

class SuccessGraphic extends ConsumerStatefulWidget {
  const SuccessGraphic({super.key});

  @override
  ConsumerState<SuccessGraphic> createState() => _SuccessGraphicState();
}

class _SuccessGraphicState extends ConsumerState<SuccessGraphic> {
  final int randomImageIndex = Random().nextInt(5) + 1;
  final int randomCalmImageIndex = Random().nextInt(2) + 1;

  @override
  Widget build(BuildContext context) {
    final calm =
        ref.watch(featureFlagProvider(FeatureFlag.calmSuccess)).value ?? false;

    return SvgPicture.asset(
      yiviAsset(
        calm
            ? "success/calm_$randomCalmImageIndex.svg"
            : "success/success_$randomImageIndex.svg",
      ),
    );
  }
}
