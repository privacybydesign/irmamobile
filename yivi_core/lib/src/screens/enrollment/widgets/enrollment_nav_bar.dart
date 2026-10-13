import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../data/feature_flags.dart";
import "../../../providers/feature_flag_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/yivi_themed_button.dart";

const double _singleButtonWidth = 160;
const double _outlineWidth = 1;

class EnrollmentNavBar extends ConsumerWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onContinue;

  const EnrollmentNavBar({super.key, this.onPrevious, this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingV2 =
        ref.watch(featureFlagProvider(FeatureFlag.onboardingV2)).value ?? false;
    if (onboardingV2) {
      return _OnboardingNavBar(onPrevious: onPrevious, onContinue: onContinue);
    }

    final theme = IrmaTheme.of(context);

    return SafeArea(
      child: Semantics(
        button: true,
        child: Container(
          height: 100,
          color: theme.themeData.colorScheme.surface,
          padding: EdgeInsets.all(theme.mediumSpacing),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Previous button (or spacer)
              Flexible(
                child: onPrevious == null
                    ? Container()
                    : Padding(
                        padding: EdgeInsets.only(right: theme.smallSpacing),
                        child: YiviThemedButton(
                          key: const Key("enrollment_previous_button"),
                          style: YiviButtonStyle.outlined,
                          label: "ui.previous",
                          onPressed: onPrevious,
                        ),
                      ),
              ),
              // Next button
              Flexible(
                child: YiviThemedButton(
                  key: const Key("enrollment_next_button"),
                  label: "ui.next",
                  onPressed: onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bar of onboarding v2: shorter buttons, a fixed width for a lone
/// "next" and an equal split when there is a "previous" as well.
class _OnboardingNavBar extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onContinue;

  const _OnboardingNavBar({this.onPrevious, this.onContinue});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final onPrevious = this.onPrevious;

    final next = YiviThemedButton(
      key: const Key("enrollment_next_button"),
      label: "ui.next",
      size: YiviButtonSize.compact,
      onPressed: onContinue,
    );

    return SafeArea(
      child: Semantics(
        button: true,
        child: ColoredBox(
          color: theme.themeData.colorScheme.surface,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              theme.mediumSpacing,
              theme.defaultSpacing,
              theme.mediumSpacing,
              theme.largeSpacing,
            ),
            child: onPrevious == null
                ? Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(width: _singleButtonWidth, child: next),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: YiviThemedButton(
                          key: const Key("enrollment_previous_button"),
                          style: YiviButtonStyle.outlined,
                          size: YiviButtonSize.compact,
                          outlineWidth: _outlineWidth,
                          label: "ui.previous",
                          onPressed: onPrevious,
                        ),
                      ),
                      SizedBox(width: theme.defaultSpacing),
                      Expanded(child: next),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
