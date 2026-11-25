import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../util/test_detection.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/surfaces/inset_group.dart";
import "../widgets/enrollment_page.dart";
import "../widgets/enrollment_point_row.dart";
import "welcome_card_fan.dart";

/// The first page of the enrollment: what Yivi is, and Get started. The
/// terms come next, as the first step.
///
/// Get started first flies the cards up and out of view while the rest
/// fades, and only then goes on. When the terms go again (back, or a back
/// swipe), the cards fly back in.
class WelcomeScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({super.key, required this.onContinue});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  /// 0: the cards in their fan; 1: flown out.
  late final _flight = AnimationController(vsync: this);

  static const _out = Duration(milliseconds: 560);
  static const _in = Duration(milliseconds: 600);

  Animation<double>? _covered;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The terms over this page: their pop (or a back swipe) brings the cards
    // back; a swipe let go before the end sends them off again.
    final covered = ModalRoute.of(context)?.secondaryAnimation;
    if (covered != _covered) {
      _covered?.removeStatusListener(_coverChanged);
      _covered = covered?..addStatusListener(_coverChanged);
    }
  }

  void _coverChanged(AnimationStatus status) {
    if (status == AnimationStatus.reverse && _flight.value > 0) {
      _flight.animateBack(0, duration: _in, curve: const Cubic(.2, .6, .5, 1));
    } else if (status == AnimationStatus.forward && _flight.value < 1) {
      _flight.animateTo(1, duration: _out, curve: const Cubic(.5, 0, .8, .4));
    }
  }

  @override
  void dispose() {
    _covered?.removeStatusListener(_coverChanged);
    _flight.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_flight.isAnimating) return;
    if (!motionStill(context)) {
      await _flight.animateTo(
        1,
        duration: _out,
        curve: const Cubic(.5, 0, .8, .4),
      );
    }
    if (mounted) widget.onContinue();
  }

  static const _values = [
    (
      Icons.person_rounded,
      "enrollment.welcome.value_1_title",
      "enrollment.welcome.value_1_text",
    ),
    (
      Icons.check_rounded,
      "enrollment.welcome.value_2_title",
      "enrollment.welcome.value_2_text",
    ),
    (
      Icons.lock_rounded,
      "enrollment.welcome.value_3_title",
      "enrollment.welcome.value_3_text",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tablet = isTabletWindow(context);
    final sideways = enrollmentSideways(context);
    // A phone held sideways: the values scroll, the button stays at the
    // bottom of the column.
    final scrollValues = sideways && !tablet;

    final cardWidth = tablet ? 300.0 : (sideways ? 180.0 : 240.0);
    final about = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: WelcomeCardFan(width: cardWidth, flight: _flight),
        ),
        const SizedBox(height: YiviSpace.x16),
        _fades(
          const EnrollmentTitle(
            "enrollment.welcome.title",
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    final values = _fades(
      InsetGroup(
        dividerIndent: 68,
        children: [
          for (final (icon, title, text) in _values)
            EnrollmentPointRow(icon: icon, titleKey: title, textKey: text),
        ],
      ),
    );

    final start = _fades(
      PrimaryPillButton(
        key: const Key("enrollment_next_button"),
        label: context.tr("enrollment.welcome.start"),
        size: tablet ? PillSize.large : PillSize.regular,
        onPressed: _start,
      ),
    );

    final action = scrollValues
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: YiviSpace.x16,
                    bottom: YiviSpace.x12,
                  ),
                  child: values,
                ),
              ),
              start,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              values,
              const SizedBox(height: YiviSpace.x24),
              start,
            ],
          );

    return EnrollmentPage(about: about, action: action, fillAction: true);
  }

  /// [child] fades out (and a little down) as the cards fly out, and back.
  Widget _fades(Widget child) => AnimatedBuilder(
    animation: _flight,
    builder: (context, child) {
      final gone = (_flight.value * 1.6).clamp(0.0, 1.0);
      return Opacity(
        opacity: 1 - gone,
        child: Transform.translate(offset: Offset(0, 16 * gone), child: child),
      );
    },
    child: child,
  );
}
