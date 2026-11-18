import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";
import "package:pinput/pinput.dart";

import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../theme/yivi_tone.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/input/pill_text_field.dart";
import "../../../widgets/resend_countdown.dart";
import "../../../widgets/sheet/sheet_layout.dart";
import "../../../widgets/surfaces/icon_square.dart";
import "../../../widgets/surfaces/surface_card.dart";
import "../../../widgets/text/translated_text.dart";

/// The label above a field on the e-mail and phone screens.
class ContactFieldLabel extends StatelessWidget {
  final String labelKey;
  final TextAlign textAlign;

  const ContactFieldLabel(
    this.labelKey, {
    super.key,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Sideways it starts the right column, level with the explanation.
      padding: EdgeInsets.fromLTRB(
        YiviSpace.x4,
        useSheetColumns(context) ? 2 : 28,
        YiviSpace.x4,
        YiviSpace.x8,
      ),
      child: TranslatedText(
        labelKey,
        textAlign: textAlign,
        style: fieldLabelStyle(context),
      ),
    );
  }
}

/// The verification code as a row of boxes, the look of [CodeBox]: 48 by 60,
/// the outline turning link blue at the next box and red for a wrong code.
/// Pinput stays underneath for the letters in e-mail codes and the SMS
/// retriever on Android.
class ContactCodeField extends StatelessWidget {
  final Key? fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool invalid;
  final SmsRetriever? smsRetriever;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final String labelKey;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// The label above the boxes; off when a heading says what goes in them.
  final bool showLabel;

  /// The boxes spread over the whole width, the first at the start and the
  /// last at the end (with the left-aligned page around them).
  final bool spread;

  /// The boxes' height (60; 56 held sideways).
  final double boxHeight;

  const ContactCodeField({
    super.key,
    this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.length,
    this.invalid = false,
    this.smsRetriever,
    this.onChanged,
    this.onCompleted,
    this.labelKey = "embedded_issuance.code_label",
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.showLabel = true,
    this.spread = false,
    this.boxHeight = 60,
  });

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    // 48 wide, narrower when a long code would not fit.
    PinTheme box(Color border, double width) => PinTheme(
      width: width,
      height: boxHeight,
      textStyle: palette
          .display(26, weight: FontWeight.w700)
          .copyWith(color: palette.heading),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2),
      ),
    );

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (showLabel) ContactFieldLabel(labelKey, textAlign: TextAlign.center),
        LayoutBuilder(
          builder: (context, constraints) {
            final fits = (constraints.maxWidth - _gap * (length - 1)) / length;
            final width = fits.isFinite ? fits.clamp(32.0, 48.0) : 48.0;
            final gap = spread && constraints.maxWidth.isFinite && length > 1
                ? ((constraints.maxWidth - width * length) / (length - 1))
                      .clamp(_gap, double.infinity)
                : _gap;
            return Pinput(
              key: fieldKey,
              controller: controller,
              focusNode: focusNode,
              smsRetriever: smsRetriever,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters ?? const [],
              textCapitalization: .characters,
              autofocus: true,
              length: length,
              mainAxisAlignment: spread ? .start : .center,
              separatorBuilder: (_) => SizedBox(width: gap),
              defaultPinTheme: box(
                invalid ? palette.danger : palette.outline,
                width,
              ),
              focusedPinTheme: box(
                invalid ? palette.danger : palette.link,
                width,
              ),
              errorPinTheme: box(palette.danger, width),
              forceErrorState: invalid,
              cursor: Container(width: 2, height: 26, color: palette.link),
              onChanged: onChanged,
              onCompleted: onCompleted,
              pinAnimationType: .scale,
              // The keyboard already gives feedback on every key; Pinput's
              // own on top of it made each digit buzz twice.
              hapticFeedbackType: .disabled,
            );
          },
        ),
      ],
    );
  }
}

/// The error under the code boxes, centred.
class ContactCodeError extends StatelessWidget {
  final String _text;
  final bool _translated;

  /// The error with the text of [textKey].
  const ContactCodeError(String textKey, {super.key})
    : _text = textKey,
      _translated = false;

  /// The error saying [text], already in the user's language.
  const ContactCodeError.text(String text, {super.key})
    : _text = text,
      _translated = true;

  @override
  Widget build(BuildContext context) => FieldError(
    _translated ? _text : context.tr(_text),
    align: TextAlign.center,
  );
}

/// Where the code went, folded into one row, with "Change". Also the
/// enrollment's e-mail step.
class ContactSentTo extends StatelessWidget {
  final String label;
  final String target;
  final bool email;
  final String changeLabel;
  final VoidCallback onChange;

  const ContactSentTo({
    required this.label,
    required this.target,
    required this.email,
    required this.changeLabel,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final (fill, ink) = palette.tone(
      email ? YiviTone.warning : YiviTone.success,
    );
    return SurfaceCard(
      key: const Key("contact_sheet_sent_to"),
      padding: const EdgeInsets.fromLTRB(
        YiviSpace.x12,
        YiviSpace.x12,
        YiviSpace.x8,
        YiviSpace.x12,
      ),
      child: Row(
        spacing: YiviSpace.x12,
        children: [
          ExcludeSemantics(
            child: IconSquare(
              icon: email ? Icons.mail_rounded : Icons.smartphone_rounded,
              fill: fill,
              ink: ink,
            ),
          ),
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: palette.caption.copyWith(
                      color: palette.secondaryText,
                    ),
                  ),
                  Text(
                    target,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette
                        .body(15, weight: FontWeight.w600)
                        .copyWith(color: palette.text),
                  ),
                ],
              ),
            ),
          ),
          SmallPill(
            key: const Key("contact_sheet_change"),
            label: changeLabel,
            onPressed: onChange,
          ),
        ],
      ),
    );
  }
}

/// A hint under the code ("Not there? Check your spam.") and "Send again".
class ContactResendRow extends StatelessWidget {
  final String hint;
  final String label;

  /// Null while a code cannot be sent again yet ("Send again in 0:42"):
  /// dimmed, without an action.
  final VoidCallback? onTap;

  const ContactResendRow({
    required this.hint,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final inline = useSheetColumns(context) && !SheetSplit.isIn(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(YiviSpace.x4, YiviSpace.x8, 0, 0),
      child: Row(
        // Sideways, outside the split's narrow column, on one line: the link
        // right after the hint.
        spacing: inline ? 16 : 0,
        children: [
          Flexible(
            fit: inline ? FlexFit.loose : FlexFit.tight,
            child: Semantics(
              liveRegion: true,
              child: Text(
                hint,
                style: palette
                    .body(15)
                    .copyWith(height: 20 / 15, color: palette.secondaryText),
              ),
            ),
          ),
          TextLink(
            key: const Key("contact_sheet_send_again"),
            label: label,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

/// Sending a code again, once [until] has passed ([ResendCountdown]); until
/// then dimmed, "Send again in 0:42".
class ContactResend extends StatelessWidget {
  final DateTime? until;
  final VoidCallback onResend;
  final String _hint;

  /// A [hint] and "Send again" on one row ([ContactResendRow]).
  const ContactResend.row({
    super.key,
    required this.until,
    required String hint,
    required this.onResend,
  }) : _hint = hint;

  @override
  Widget build(BuildContext context) {
    return ResendCountdown(
      until: until,
      builder: (context, left) {
        final waiting = left == null
            ? null
            : context.tr("contact_sheet.send_again_in", {"time": left});
        final onTap = left == null ? onResend : null;
        return ContactResendRow(
          hint: _hint,
          label: waiting ?? context.tr("contact_sheet.send_again"),
          onTap: onTap,
        );
      },
    );
  }
}
