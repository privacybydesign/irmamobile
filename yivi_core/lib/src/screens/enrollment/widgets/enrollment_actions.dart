import "dart:ui" show lerpDouble;

import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/bars/floating_bar_placement.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "enrollment_page.dart";

/// A step's buttons: the way on ([primary], the red one), and on a question
/// the other answer ([secondary], a text button at its left).
@immutable
class EnrollmentStepActions {
  final String primary;
  final VoidCallback? onPrimary;
  final Key? primaryKey;
  final String? secondary;
  final VoidCallback? onSecondary;
  final Key? secondaryKey;

  const EnrollmentStepActions({
    required this.primary,
    required this.onPrimary,
    this.primaryKey,
    this.secondary,
    this.onSecondary,
    this.secondaryKey,
  });

  bool get pair => secondary != null;
}

/// Whether the steps' buttons are drawn by the [EnrollmentActionsLayer] over
/// the pages (a phone held upright): a page then only keeps their room. Held
/// sideways and on a tablet each page draws its own ([EnrollmentStepButtons]).
class EnrollmentActionsScope extends InheritedWidget {
  final bool layered;

  const EnrollmentActionsScope({
    super.key,
    required this.layered,
    required super.child,
  });

  static bool layeredOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<EnrollmentActionsScope>()
          ?.layered ??
      false;

  /// Whether the layer is for [context]: a phone held upright.
  static bool fits(BuildContext context) =>
      !enrollmentSideways(context) && !isTabletWindow(context);

  @override
  bool updateShouldNotify(EnrollmentActionsScope oldWidget) =>
      layered != oldWidget.layered;
}

/// A page's buttons where it draws them itself, or their room where the
/// layer over the pages draws them.
class EnrollmentStepButtons extends StatelessWidget {
  final EnrollmentStepActions actions;

  const EnrollmentStepButtons({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    if (EnrollmentActionsScope.layeredOf(context)) {
      return const SizedBox(height: PillSize.regularHeight);
    }
    final size = isTabletWindow(context) ? PillSize.large : PillSize.regular;
    final primary = PrimaryPillButton(
      key: actions.primaryKey,
      label: actions.primary,
      size: size,
      onPressed: actions.onPrimary,
    );
    if (!actions.pair) return primary;
    return Row(
      spacing: YiviSpace.x8,
      children: [
        Expanded(
          child: PillButton(
            key: actions.secondaryKey,
            label: actions.secondary!,
            style: PillStyle.text,
            size: size,
            onPressed: actions.onSecondary,
          ),
        ),
        Expanded(child: primary),
      ],
    );
  }
}

/// The buttons of the step on screen, over the pages, so they stay where
/// they are while a page comes in or goes, like the bar at the top. Between
/// a step with one button and one with two, the red one narrows into the
/// right half (its label changing on the way) and the other answer comes in
/// at its left; back the other way. A step without buttons (the PIN) lets
/// them sink away.
class EnrollmentActionsLayer extends StatefulWidget {
  /// Null: no buttons on this step.
  final EnrollmentStepActions? actions;

  const EnrollmentActionsLayer({super.key, required this.actions});

  @override
  State<EnrollmentActionsLayer> createState() => _EnrollmentActionsLayerState();
}

class _EnrollmentActionsLayerState extends State<EnrollmentActionsLayer> {
  /// The last buttons there were, to fade out with when a step has none.
  EnrollmentStepActions? _last;

  /// As long as the steps' own change (the shared axis).
  static const _duration = Duration(milliseconds: 410);

  @override
  Widget build(BuildContext context) {
    final actions = widget.actions ?? _last;
    if (widget.actions != null) _last = widget.actions;
    final shown = widget.actions != null;
    final still = MediaQuery.disableAnimationsOf(context);
    final duration = still ? Duration.zero : _duration;
    if (actions == null) return const SizedBox.shrink();
    return Positioned(
      left: 16,
      right: 16,
      bottom: FloatingBarPlacement.buttonBottom(context),
      height: PillSize.regularHeight,
      child: IgnorePointer(
        ignoring: !shown,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: still ? Duration.zero : YiviMotion.standard,
          child: AnimatedSlide(
            offset: shown ? Offset.zero : const Offset(0, 0.3),
            duration: duration,
            curve: YiviMotion.ease,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: actions.pair ? 1 : 0),
              duration: duration,
              curve: YiviMotion.ease,
              builder: (context, pair, _) => LayoutBuilder(
                builder: (context, constraints) {
                  final full = constraints.maxWidth;
                  final half = (full - YiviSpace.x8) / 2;
                  final primaryWidth = lerpDouble(full, half, pair)!;
                  return Stack(
                    children: [
                      if (actions.secondary case final secondary?)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: half,
                          child: Opacity(
                            opacity: pair,
                            child: Transform.translate(
                              offset: Offset(-24 * (1 - pair), 0),
                              child: _Fade(
                                id: secondary,
                                child: PillButton(
                                  key: actions.secondaryKey,
                                  label: secondary,
                                  style: PillStyle.text,
                                  size: PillSize.regular,
                                  onPressed: actions.onSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: primaryWidth,
                        child: _Fade(
                          id: actions.primary,
                          child: PrimaryPillButton(
                            key: actions.primaryKey,
                            label: actions.primary,
                            size: PillSize.regular,
                            onPressed: actions.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [child] cross-fades into the next one when [id] (its label) changes.
class _Fade extends StatelessWidget {
  final String id;
  final Widget child;

  const _Fade({required this.id, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220),
    layoutBuilder: (current, previous) =>
        Stack(fit: StackFit.expand, children: [...previous, ?current]),
    child: KeyedSubtree(key: ValueKey(id), child: child),
  );
}
