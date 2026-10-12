import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../../../package_name.dart";
import "../../../../data/feature_flags.dart";
import "../../../../providers/feature_flag_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../widgets/bullet_list.dart";
import "../../../../widgets/translated_text.dart";

const _pointKeys = [
  "enrollment.terms_and_conditions.point_1",
  "enrollment.terms_and_conditions.point_2",
  "enrollment.terms_and_conditions.point_3",
];

const _onboardingPointKeys = [
  "enrollment.onboarding_v2.point_1",
  "enrollment.onboarding_v2.point_2",
  "enrollment.onboarding_v2.point_3",
];

const double _checkSize = 22;
// Lines the check mark up with the first line of text.
const double _checkTopSpacing = 1;
const double _checkTextSpacing = 12;

class TermsBulletList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingV2 =
        ref.watch(featureFlagProvider(FeatureFlag.onboardingV2)).value ?? false;
    if (onboardingV2) return const _OnboardingPoints();

    return BulletList(
      leading: Icon(Icons.check, color: IrmaTheme.of(context).success),
      translationKeys: _pointKeys,
    );
  }
}

class _OnboardingPoints extends StatelessWidget {
  const _OnboardingPoints();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      spacing: theme.defaultSpacing,
      children: [
        for (final key in _onboardingPointKeys)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: _checkTopSpacing),
                child: ExcludeSemantics(
                  child: SvgPicture.asset(
                    yiviAsset("ui/onboarding_check.svg"),
                    width: _checkSize,
                    height: _checkSize,
                  ),
                ),
              ),
              const SizedBox(width: _checkTextSpacing),
              Expanded(child: TranslatedText(key, style: theme.boldBody)),
            ],
          ),
      ],
    );
  }
}
