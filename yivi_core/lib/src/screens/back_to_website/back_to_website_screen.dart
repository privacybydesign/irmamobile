import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../providers/preferences_provider.dart";
import "../../theme/theme.dart";
import "../../util/navigation.dart";
import "../../widgets/translated_text.dart";

const Color _backgroundColor = Color(0xFFF7FAFC);
const double _contentTopSpacing = 56;
const double _contentSideSpacing = 20;
const double _buttonBarBottomSpacing = 32;
const double _buttonHeight = 48;
const double _sketchWidth = 260;
const double _sketchRadius = 14;
const double _sketchBorderWidth = 2;
const double _sketchBarHeight = 28;
const double _sketchBarSpacing = 10;
const double _sketchBarGap = 6;
const double _sketchDotSize = 8;
const double _sketchUrlHeight = 14;
const double _sketchBodyTopSpacing = 18;
const double _sketchBodyBottomSpacing = 20;
const double _sketchBodyGap = 12;
const double _sketchButtonHeight = 40;
const double _sketchButtonRing = 4;
const double _sketchRingOpacity = 0.18;
const Color _sketchBarColor = Color(0xFFF2F0EE);
const Color _sketchButtonColor = Color(0xFFE12747);
const Duration _tapPulseDuration = Duration(milliseconds: 2400);
const double _tapPulseScale = 0.94;
const double _smallTextSize = 14;

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
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  _contentSideSpacing,
                  _contentTopSpacing,
                  _contentSideSpacing,
                  theme.defaultSpacing,
                ),
                child: Column(
                  spacing: theme.mediumSpacing,
                  children: [
                    TranslatedText(
                      "back_to_website.title",
                      style: theme.textTheme.displayMedium!.copyWith(
                        height: 32 / 24,
                      ),
                      textAlign: TextAlign.center,
                      isHeader: true,
                    ),
                    const TranslatedText(
                      "back_to_website.text",
                      textAlign: TextAlign.center,
                    ),
                    const _BrowserSketch(),
                    TranslatedText(
                      "back_to_website.hint",
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontSize: _smallTextSize,
                        height: 20 / _smallTextSize,
                        color: theme.neutralExtraDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                theme.defaultSpacing,
                theme.defaultSpacing,
                theme.defaultSpacing,
                _buttonBarBottomSpacing,
              ),
              child: SizedBox(
                width: double.infinity,
                height: _buttonHeight,
                child: TextButton(
                  key: const Key("back_to_website_other_button"),
                  onPressed: context.goHomeScreen,
                  child: TranslatedText(
                    "back_to_website.other",
                    style: theme.textButtonTextStyle.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
      child: Container(
        width: _sketchWidth,
        decoration: BoxDecoration(
          color: theme.light,
          borderRadius: BorderRadius.circular(_sketchRadius),
          border: Border.all(
            color: theme.neutralLight,
            width: _sketchBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(0, 2),
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            _sketchRadius - _sketchBorderWidth,
          ),
          child: Column(
            children: [
              ColoredBox(
                color: _sketchBarColor,
                child: SizedBox(
                  height: _sketchBarHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _sketchBarSpacing,
                    ),
                    child: Row(
                      spacing: _sketchBarGap,
                      children: [
                        SizedBox.square(
                          dimension: _sketchDotSize,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.neutralLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.light,
                              borderRadius: BorderRadius.circular(
                                _sketchUrlHeight / 2,
                              ),
                            ),
                            child: const SizedBox(height: _sketchUrlHeight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  theme.defaultSpacing,
                  _sketchBodyTopSpacing,
                  theme.defaultSpacing,
                  _sketchBodyBottomSpacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: _sketchBodyGap,
                  children: [
                    TranslatedText(
                      "back_to_website.sketch_label",
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontSize: _smallTextSize,
                        height: 19 / _smallTextSize,
                        fontWeight: FontWeight.w700,
                        color: theme.neutralExtraDark,
                      ),
                    ),
                    const _TapPulse(child: _SketchButton()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SketchButton extends StatelessWidget {
  const _SketchButton();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _sketchButtonColor,
        borderRadius: theme.borderRadius,
        boxShadow: [
          BoxShadow(
            color: _sketchButtonColor.withValues(alpha: _sketchRingOpacity),
            spreadRadius: _sketchButtonRing,
          ),
        ],
      ),
      child: SizedBox(
        height: _sketchButtonHeight,
        child: Center(
          child: TranslatedText(
            "back_to_website.sketch_button",
            style: theme.textTheme.bodyMedium!.copyWith(
              fontSize: _smallTextSize,
              fontWeight: FontWeight.w700,
              color: theme.light,
            ),
          ),
        ),
      ),
    );
  }
}

/// Presses its child in and out on a loop, like a finger tapping it. Holds
/// still when the system asks for fewer animations.
class _TapPulse extends StatefulWidget {
  final Widget child;

  const _TapPulse({required this.child});

  @override
  State<_TapPulse> createState() => _TapPulseState();
}

class _TapPulseState extends State<_TapPulse>
    with SingleTickerProviderStateMixin {
  // One loop: rest, press in, press out, rest.
  static final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(1), weight: 60),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: _tapPulseScale,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 10,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: _tapPulseScale,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 10,
    ),
    TweenSequenceItem(tween: ConstantTween(1), weight: 20),
  ]);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _tapPulseDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
      return;
    }

    if (!_controller.isAnimating) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _controller.drive(_scale), child: widget.child);
}
