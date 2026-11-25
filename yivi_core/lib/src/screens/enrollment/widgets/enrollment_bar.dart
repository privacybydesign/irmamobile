import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/bars/app_bar.dart";
import "../enrollment_state.dart";

/// The height of the enrollment's bar under the status bar: the app bar's
/// row and the progress line under it.
const double enrollmentBarHeight =
    YiviAppBar.toolbarHeight + EnrollmentBar.lineHeight;

/// How much room the pages of the numbered steps leave at the top for the
/// [EnrollmentBar] that floats over them. Zero (no bar) on the welcome page
/// and while setting up.
class EnrollmentBarSpace extends InheritedWidget {
  final double height;

  const EnrollmentBarSpace({
    super.key,
    required this.height,
    required super.child,
  });

  static double of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<EnrollmentBarSpace>()
          ?.height ??
      0;

  @override
  bool updateShouldNotify(EnrollmentBarSpace oldWidget) =>
      height != oldWidget.height;
}

/// The one bar of the numbered steps: back, "Step n of N", and a thin line
/// filled to n of N. It sits over the steps' pages, on a band of its own, so
/// it never moves while a page slides in or out under it; only the label
/// changes and the line grows (or shrinks) to the next step.
class EnrollmentBar extends StatelessWidget {
  static const double lineHeight = 3;

  /// The step shown, or null on a page without one: the bar is then gone.
  final EnrollmentStepNumber? step;

  /// "Step n of N", already translated.
  final String label;

  /// Back, or null where there is no way back (Face ID: the account is
  /// being made).
  final VoidCallback? onBack;

  const EnrollmentBar({
    super.key,
    required this.step,
    required this.label,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final tablet = isTabletWindow(context);
    final fraction = step == null ? 0.0 : step!.number / step!.total;
    final duration = YiviMotion.duration(context, YiviMotion.page);

    final bar = ColoredBox(
      key: const Key("enrollment_bar"),
      color: palette.background,
      child: Padding(
        padding: EdgeInsets.only(top: padding.top),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: YiviAppBar.toolbarHeight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16 + padding.left,
                  YiviAppBar.buttonTop,
                  16 + padding.right,
                  4,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 52),
                      child: Semantics(
                        header: true,
                        child: Text(
                          label,
                          key: const Key("enrollment_step_label"),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: palette
                              .body(tablet ? 15 : 14)
                              .copyWith(color: palette.secondaryText),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedOpacity(
                        opacity: onBack == null ? 0 : 1,
                        duration: YiviMotion.duration(
                          context,
                          YiviMotion.quick,
                        ),
                        child: IgnorePointer(
                          ignoring: onBack == null,
                          child: ExcludeSemantics(
                            excluding: onBack == null,
                            child: YiviBackButton(onTap: onBack ?? () {}),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // The line: solid, so a page sliding under the bar never shows
            // through it.
            ExcludeSemantics(
              child: SizedBox(
                height: lineHeight,
                child: ColoredBox(
                  color: palette.isDark
                      ? const Color(0xFF3A3A3C)
                      : const Color(0xFFCDD5DB),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: fraction),
                    duration: duration,
                    curve: YiviMotion.ease,
                    builder: (context, value, _) => FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: value,
                      child: ColoredBox(color: palette.successText),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return AnimatedOpacity(
      opacity: step == null ? 0 : 1,
      duration: YiviMotion.duration(context, YiviMotion.standard),
      child: IgnorePointer(ignoring: step == null, child: bar),
    );
  }
}
