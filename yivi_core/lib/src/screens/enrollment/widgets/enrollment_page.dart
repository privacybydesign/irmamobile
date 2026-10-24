import "dart:math";

import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../util/tablet.dart";
import "../../../widgets/centred_max_width.dart";
import "../../../widgets/fill_scroll_view.dart";
import "../../../widgets/glass/floating_bar_placement.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/translated_text.dart";

/// Whether an enrollment page uses the tablet sizes: bigger titles, cards
/// and icon tile.
bool enrollmentTablet(BuildContext context) => context.isTabletDevice;

/// Whether an enrollment page lays out in two columns: whenever the screen
/// is wider than high, on a phone and on a tablet.
bool enrollmentSideways(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width > size.height;
}

/// Most a tablet's upright column is wide.
const double enrollmentColumnMaxWidth = 560;

/// Most the two columns are wide together on a tablet held sideways.
const double _sidewaysMaxWidth = 1000;

/// The height of the bar with the back and Skip buttons.
const double _topBarHeight = 44;

/// One page of the enrollment, in every size, by one rule:
/// - wider than high (a phone or tablet held sideways): two columns, what
///   the page is about ([about]) on the left, what to do ([action]) on the
///   right, under the thumb;
/// - a phone held upright: [about] fills the top and [action] sits low, its
///   lowest button where the app's bottom-bar buttons are;
/// - a tablet held upright: one centred column of at most
///   [enrollmentColumnMaxWidth].
///
/// [leading] (the back button) and [trailing] (Skip) float in a bar at the
/// top. Either part scrolls when it does not fit (a small phone, large text,
/// the keyboard up).
class EnrollmentPage extends StatelessWidget {
  final Widget? about;
  final Widget action;
  final Widget? leading;
  final Widget? trailing;

  /// Gives [action] the full height of its column on a phone held
  /// sideways, so it can keep its buttons at the bottom and scroll the rest.
  final bool fillAction;

  const EnrollmentPage({
    super.key,
    this.about,
    required this.action,
    this.leading,
    this.trailing,
    this.fillAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final sideways = enrollmentSideways(context);
    final tablet = enrollmentTablet(context);
    final hasBar = leading != null || trailing != null;
    final barSpace = hasBar ? _topBarHeight + 8 : 0.0;

    final Widget body;
    if (sideways) {
      body = _Sideways(
        about: about,
        action: action,
        tablet: tablet,
        top: barSpace,
        fillAction: fillAction && !tablet,
      );
    } else if (tablet) {
      body = _UprightTablet(about: about, action: action, top: barSpace);
    } else {
      body = _UprightPhone(
        about: about,
        action: action,
        top: barSpace,
        // Read here: inside the Scaffold the keyboard is taken off already.
        keyboard: MediaQuery.viewInsetsOf(context).bottom > 0,
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: body),
            if (hasBar)
              Positioned(
                left: 16,
                right: 16,
                top: FloatingBarPlacement.topGap(context),
                child: SizedBox(
                  height: _topBarHeight,
                  child: Row(children: [?leading, const Spacer(), ?trailing]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fills the height it is given and centres [child] in it, scrolling when
/// [child] is taller.
class _Centred extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Centred({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return FillScrollView(
      padding: padding,
      child: Center(child: child),
    );
  }
}

class _Sideways extends StatelessWidget {
  final Widget? about;
  final Widget action;
  final bool tablet;
  final double top;
  final bool fillAction;

  const _Sideways({
    required this.about,
    required this.action,
    required this.tablet,
    required this.top,
    required this.fillAction,
  });

  @override
  Widget build(BuildContext context) {
    // The page runs to the bottom of the screen (the SafeArea above takes
    // the sides and the top): clear of the home indicator, or 16 from the
    // keyboard or the edge.
    final bottom = max(
      tablet ? 20.0 : 16.0,
      MediaQuery.paddingOf(context).bottom,
    );
    final columns = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tablet ? 80 : 24,
      children: [
        if (about != null)
          Expanded(
            child: _Centred(
              padding: EdgeInsets.only(top: top, bottom: bottom),
              child: about!,
            ),
          ),
        Expanded(
          child: fillAction
              ? Padding(
                  padding: EdgeInsets.only(top: top, bottom: bottom),
                  child: action,
                )
              : _Centred(
                  padding: EdgeInsets.only(top: top, bottom: bottom),
                  child: action,
                ),
        ),
      ],
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tablet ? 40 : 16),
      child: CentredMaxWidth(maxWidth: _sidewaysMaxWidth, child: columns),
    );
  }
}

class _UprightTablet extends StatelessWidget {
  final Widget? about;
  final Widget action;
  final double top;

  const _UprightTablet({
    required this.about,
    required this.action,
    required this.top,
  });

  @override
  Widget build(BuildContext context) {
    return _Centred(
      padding: EdgeInsets.fromLTRB(40, top + 24, 40, 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: enrollmentColumnMaxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 40,
          children: [?about, action],
        ),
      ),
    );
  }
}

class _UprightPhone extends StatelessWidget {
  final Widget? about;
  final Widget action;
  final double top;
  final bool keyboard;

  const _UprightPhone({
    required this.about,
    required this.action,
    required this.top,
    required this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    // The keyboard takes the bottom: the action then ends just above it.
    final bottom = keyboard ? 16.0 : FloatingBarPlacement.buttonBottom(context);
    // At least the height of the screen: the empty first child and the two
    // equal gaps put [about] in the middle of the room above [action]. No
    // intrinsic sizes, which a field with a LayoutBuilder cannot give.
    return FillScrollView(
      padding: EdgeInsets.fromLTRB(16, top, 16, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox.shrink(),
          if (about != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: about),
            ),
          action,
        ],
      ),
    );
  }
}

/// "Step 1 of 3" above an enrollment page's title.
class EnrollmentStepLabel extends StatelessWidget {
  final String text;

  const EnrollmentStepLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Text(
      text,
      textAlign: enrollmentSideways(context)
          ? TextAlign.start
          : TextAlign.center,
      style: palette
          .body(enrollmentTablet(context) ? 15 : 14)
          .copyWith(color: palette.secondaryText),
    );
  }
}

/// An enrollment page's title: 24, or 32 on a tablet.
class EnrollmentTitle extends StatelessWidget {
  final String translationKey;
  final TextAlign? textAlign;

  const EnrollmentTitle(this.translationKey, {super.key, this.textAlign});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final tablet = enrollmentTablet(context);
    return TranslatedText(
      translationKey,
      isHeader: true,
      textAlign: textAlign,
      style: palette
          .display(tablet ? 32 : 24, weight: FontWeight.w700)
          .copyWith(height: tablet ? 40 / 32 : 32 / 24),
    );
  }
}

/// The explanation under an enrollment page's title.
class EnrollmentLead extends StatelessWidget {
  final String translationKey;
  final Map<String, String> translationParams;
  final TextAlign? textAlign;

  const EnrollmentLead(
    this.translationKey, {
    super.key,
    this.translationParams = const {},
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final tablet = enrollmentTablet(context);
    return TranslatedText(
      translationKey,
      translationParams: translationParams,
      textAlign: textAlign,
      style: palette
          .body(tablet ? 17 : 16)
          .copyWith(height: tablet ? 26 / 17 : 24 / 16),
    );
  }
}

/// A glass pill with a word on it, for "Skip" in the top bar.
class EnrollmentBarTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const EnrollmentBarTextButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        scale: PressScale.glass,
        child: GlassSurface(
          shape: const StadiumBorder(),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const StadiumBorder(),
              highlightColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              onTap: onPressed,
              child: Container(
                height: _topBarHeight,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: palette.display(15, weight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
