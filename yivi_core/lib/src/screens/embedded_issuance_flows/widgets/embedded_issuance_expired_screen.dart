import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:go_router/go_router.dart";

import "../../../../package_name.dart";
import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/translated_text.dart";

/// Shown when the verification session/code has expired on the issuer server,
/// e.g. because the user left the app to fetch their code and came back too
/// late. Unlike the generic error screen this explains what happened and its
/// primary action restarts the flow (request a fresh code) rather than
/// retrying the now-dead session.
class EmbeddedIssuanceExpiredScreen extends StatelessWidget {
  const EmbeddedIssuanceExpiredScreen({
    super.key,
    required this.titleTranslationKey,
    required this.bodyTranslationKey,
    required this.restartButtonTranslationKey,
    required this.cancelButtonTranslationKey,
    required this.onRestart,
  });

  final String titleTranslationKey;
  final String bodyTranslationKey;
  final String restartButtonTranslationKey;
  final String cancelButtonTranslationKey;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      appBar: IrmaAppBar(titleTranslationKey: titleTranslationKey),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: .all(theme.defaultSpacing),
            child: SizedBox(
              width: .infinity,
              child: Builder(
                builder: (context) {
                  final orientation = MediaQuery.of(context).orientation;

                  if (orientation == .landscape) {
                    return Row(
                      mainAxisSize: .max,
                      mainAxisAlignment: .center,
                      children: [
                        Flexible(
                          child: TranslatedText(
                            bodyTranslationKey,
                            textAlign: .start,
                          ),
                        ),
                        SizedBox(width: theme.largeSpacing),
                        Flexible(
                          child: SvgPicture.asset(
                            height: 200,
                            yiviAsset("error/general_error_illustration.svg"),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    mainAxisSize: .max,
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .center,
                    children: [
                      SizedBox(height: theme.largeSpacing),
                      SvgPicture.asset(
                        yiviAsset("error/general_error_illustration.svg"),
                      ),
                      SizedBox(height: theme.largeSpacing),
                      TranslatedText(bodyTranslationKey, textAlign: .center),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: restartButtonTranslationKey,
        secondaryButtonLabel: cancelButtonTranslationKey,
        onPrimaryPressed: onRestart,
        onSecondaryPressed: context.pop,
      ),
    );
  }
}
