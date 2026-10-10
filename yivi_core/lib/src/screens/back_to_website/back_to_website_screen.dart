import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../providers/preferences_provider.dart";
import "../../theme/theme.dart";
import "../../util/navigation.dart";
import "../../widgets/translated_text.dart";

const double _sketchBorderWidth = 2;
const double _sketchDotSize = 8;

/// Shown once after onboarding when the install started on a website, so the
/// user returns to the browser instead of staying in an empty app.
class BackToWebsiteScreen extends ConsumerStatefulWidget {
  const BackToWebsiteScreen({super.key});

  @override
  ConsumerState<BackToWebsiteScreen> createState() =>
      _BackToWebsiteScreenState();
}

class _BackToWebsiteScreenState extends ConsumerState<BackToWebsiteScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(preferencesProvider).markBackToWebsiteShown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.all(theme.mediumSpacing),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 2 * theme.mediumSpacing,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TranslatedText(
                    "back_to_website.title",
                    style: theme.textTheme.displayLarge,
                    isHeader: true,
                  ),
                  SizedBox(height: theme.defaultSpacing),
                  const TranslatedText("back_to_website.text"),
                  SizedBox(height: theme.mediumSpacing),
                  const _BrowserSketch(),
                  SizedBox(height: theme.mediumSpacing),
                  TranslatedText(
                    "back_to_website.hint",
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: theme.neutralDark,
                    ),
                  ),
                  SizedBox(height: theme.mediumSpacing),
                  Center(
                    child: TextButton(
                      key: const Key("back_to_website_other_button"),
                      onPressed: context.goHomeScreen,
                      child: TranslatedText(
                        "back_to_website.other",
                        style: theme.textButtonTextStyle.copyWith(
                          fontWeight: FontWeight.normal,
                          color: theme.link,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A browser window with the "Open Yivi app" button the website shows. Purely
/// illustrative: the text above it says the same.
class _BrowserSketch extends StatelessWidget {
  const _BrowserSketch();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.light,
          borderRadius: theme.borderRadius,
          border: Border.all(
            color: theme.neutralLight,
            width: _sketchBorderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: theme.borderRadius,
          child: Column(
            children: [
              ColoredBox(
                color: theme.neutralExtraLight,
                child: Padding(
                  padding: EdgeInsets.all(theme.smallSpacing),
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: EdgeInsets.only(right: theme.tinySpacing),
                          child: SizedBox.square(
                            dimension: _sketchDotSize,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: theme.neutral,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(width: theme.smallSpacing),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.light,
                            borderRadius: BorderRadius.circular(
                              theme.smallSpacing,
                            ),
                          ),
                          child: SizedBox(height: theme.mediumSpacing),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(theme.largeSpacing),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: theme.borderRadius,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: theme.mediumSpacing,
                      vertical: theme.defaultSpacing - theme.tinySpacing,
                    ),
                    child: TranslatedText(
                      "back_to_website.sketch_button",
                      style: theme.textTheme.labelLarge!.copyWith(
                        color: theme.light,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
