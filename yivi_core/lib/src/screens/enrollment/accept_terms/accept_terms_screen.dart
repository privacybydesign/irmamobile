import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../data/feature_flags.dart";
import "../../../providers/feature_flag_provider.dart";
import "../../../theme/theme.dart";
import "../../../widgets/translated_text.dart";
import "../widgets/enrollment_nav_bar.dart";
import "widgets/error_reporting_check_box.dart";
import "widgets/terms_bullet_list.dart";
import "widgets/terms_check_box.dart";

const double _onboardingTextSpacing = 12;

// for first time terms acceptance
class AcceptTermsScreen extends ConsumerWidget {
  final bool isAccepted;
  final Function(bool) onToggleAccepted;
  final VoidCallback onContinue;
  final VoidCallback onPrevious;

  const AcceptTermsScreen({
    required this.isAccepted,
    required this.onToggleAccepted,
    required this.onContinue,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final onboardingV2 =
        ref.watch(featureFlagProvider(FeatureFlag.onboardingV2)).value ?? false;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraint) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraint.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      theme.mediumSpacing,
                      theme.mediumSpacing,
                      theme.mediumSpacing,
                      onboardingV2 ? theme.smallSpacing : theme.mediumSpacing,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        SizedBox(height: theme.mediumSpacing),
                        TranslatedText(
                          "enrollment.terms_and_conditions.title",
                          style: theme.textTheme.displayLarge,
                          textAlign: TextAlign.start,
                        ),
                        SizedBox(
                          height: onboardingV2
                              ? _onboardingTextSpacing
                              : theme.mediumSpacing,
                        ),

                        // Explanation
                        const TranslatedText(
                          "enrollment.terms_and_conditions.explanation",
                          textAlign: TextAlign.start,
                        ),
                        SizedBox(height: theme.mediumSpacing),

                        TermsBulletList(),
                        const Spacer(),

                        TermsCheckBox(
                          isAccepted: isAccepted,
                          onToggleAccepted: onToggleAccepted,
                        ),

                        // If not in landscape mode, add some spacing
                        if (MediaQuery.of(context).orientation ==
                            Orientation.portrait)
                          SizedBox(height: theme.defaultSpacing),

                        ErrorReportingCheckBox(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: EnrollmentNavBar(
        onPrevious: onPrevious,
        onContinue: isAccepted ? onContinue : null,
      ),
    );
  }
}
