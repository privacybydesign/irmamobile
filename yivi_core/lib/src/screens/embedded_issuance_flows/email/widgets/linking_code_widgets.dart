import "package:material_ui/material_ui.dart";
import "package:pinput/pinput.dart";

import "../../../../theme/theme.dart";
import "../../../../widgets/translated_text.dart";

const _digitWidth = 46.0;
const _digitHeight = 58.0;
const _digitRadius = 8.0;
const _digitLineWidth = 2.0;
const _digitFontSize = 24.0;
const _digitFocusedFill = Color(0xFFF4F8FC);

const _statusIconSize = 18.0;
const _statusGreen = Color(0xFF00602A);

const _spinnerSize = 18.0;
const _spinnerStrokeWidth = 2.5;
const _spinnerTrackOpacity = 0.4;
// Where the arc of the spinner stops when the user asked for less motion.
const _spinnerStillValue = 0.25;

/// The boxes of the code field on the e-mail linking screens
/// (`FeatureFlag.emailLinking`): white, with a line at the bottom that turns
/// blue once a digit is in or the box has focus.
class LinkingPinThemes {
  final PinTheme normal;
  final PinTheme focused;
  final PinTheme filled;

  factory LinkingPinThemes(IrmaThemeData theme, {required bool invalid}) {
    final fill = invalid ? theme.errorSurface : theme.light;
    final line = invalid ? theme.error : theme.neutralDark;
    final activeLine = invalid ? theme.error : theme.link;

    final normal = PinTheme(
      width: _digitWidth,
      height: _digitHeight,
      textStyle: theme.textTheme.bodyLarge!.copyWith(fontSize: _digitFontSize),
      decoration: _digitDecoration(fill: fill, line: line),
    );

    return LinkingPinThemes._(
      normal: normal,
      focused: normal.copyWith(
        decoration: _digitDecoration(
          fill: invalid ? fill : _digitFocusedFill,
          line: activeLine,
        ),
      ),
      filled: normal.copyWith(
        decoration: _digitDecoration(fill: fill, line: activeLine),
      ),
    );
  }

  const LinkingPinThemes._({
    required this.normal,
    required this.focused,
    required this.filled,
  });
}

// A border with rounded corners has to be uniform, so the line is the last
// stretch of a gradient with hard stops, clipped by the rounded top corners.
BoxDecoration _digitDecoration({required Color fill, required Color line}) {
  final lineStart = 1 - _digitLineWidth / _digitHeight;

  return BoxDecoration(
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(_digitRadius),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.shade300,
        offset: const Offset(0.0, 1.0),
        blurRadius: 3.0,
      ),
    ],
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [fill, fill, line, line],
      stops: [0, lineStart, lineStart, 1],
    ),
  );
}

/// Says the code in the field came from the link in the e-mail.
class CodeFromLinkStatus extends StatelessWidget {
  const CodeFromLinkStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(Icons.check_circle, color: theme.success, size: _statusIconSize),
          SizedBox(width: theme.smallSpacing),
          Expanded(
            child: TranslatedText(
              "email_linking.verify_code.filled_from_link",
              style: theme.textTheme.bodyMedium!.copyWith(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                color: _statusGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress indicator for the primary button while the code is checked.
class LinkingButtonSpinner extends StatelessWidget {
  const LinkingButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final still = MediaQuery.disableAnimationsOf(context);

    return SizedBox.square(
      dimension: _spinnerSize,
      child: CircularProgressIndicator(
        value: still ? _spinnerStillValue : null,
        strokeWidth: _spinnerStrokeWidth,
        color: theme.light,
        backgroundColor: theme.light.withValues(alpha: _spinnerTrackOpacity),
      ),
    );
  }
}
