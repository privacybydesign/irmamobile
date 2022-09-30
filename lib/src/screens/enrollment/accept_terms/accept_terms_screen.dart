import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/enrollment/accept_terms/widgets/terms_bullet_list.dart';
import 'package:irmamobile/src/widgets/bullet_list.dart';
import 'package:irmamobile/src/screens/enrollment/accept_terms/widgets/terms_check_box.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_markdown.dart';

import '../../../widgets/translated_text.dart';
import '../widgets/enrollment_nav_bar.dart';

class AcceptTermsScreen extends StatelessWidget {
  static const String routeName = 'terms';

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
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraint) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraint.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.all(theme.mediumSpacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TranslatedText(
                          'enrollment.terms_and_conditions.title',
                          style: theme.textTheme.headline1,
                          textAlign: TextAlign.start,
                        ),
                        SizedBox(height: theme.mediumSpacing),

                        // Explanation
                        IrmaMarkdown(
                          FlutterI18n.translate(
                            context,
                            'enrollment.terms_and_conditions.explanation_markdown',
                          ),
                        ),
                        SizedBox(height: theme.mediumSpacing),

                        // Bullet points
                        TermsBulletList(),
                        const Spacer(),

                        TermsCheckBox(
                          isAccepted: isAccepted,
                          onToggleAccepted: onToggleAccepted,
                        )
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
