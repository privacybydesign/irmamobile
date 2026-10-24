import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";
import "package:pinput/pinput.dart";

import "../../../theme/theme.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/keyboard_animation_listener.dart";
import "../../../widgets/pill_text_field.dart";
import "../../../widgets/translated_text.dart";

/// A full-screen e-mail or phone step: [before], the [field] and [after] in
/// a column that scrolls, the field kept in view while it has focus (at
/// [fieldAlignment], see [Scrollable.ensureVisible]) and the page scrolled
/// back to the top when it loses it. A tap outside the field closes the
/// keyboard.
///
/// With a [keyboardButton] the [bottomBar] gives way to that button while
/// the keyboard is up, right above it.
class ContactScrollPage extends StatefulWidget {
  final PreferredSizeWidget appBar;
  final FocusNode focusNode;
  final double fieldAlignment;
  final List<Widget> before;
  final Widget field;
  final List<Widget> after;
  final Widget bottomBar;
  final Widget? keyboardButton;

  const ContactScrollPage({
    super.key,
    required this.appBar,
    required this.focusNode,
    required this.fieldAlignment,
    required this.before,
    required this.field,
    this.after = const [],
    required this.bottomBar,
    this.keyboardButton,
  });

  @override
  State<ContactScrollPage> createState() => _ContactScrollPageState();
}

class _ContactScrollPageState extends State<ContactScrollPage> {
  final _scrollController = ScrollController();
  final _fieldPositionKey = GlobalKey();

  // Keeps the scrollable's state when the scaffold's key changes with the
  // keyboard (see [ContactScrollPage.keyboardButton]).
  final _scrollableKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (widget.focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final fieldContext = _fieldPositionKey.currentContext;
        if (fieldContext == null) {
          return;
        }

        Scrollable.ensureVisible(
          fieldContext,
          alignment: widget.fieldAlignment,
          duration: const Duration(milliseconds: 300),
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          return;
        }
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final media = MediaQuery.of(context);
    final keyboardButton = widget.keyboardButton;
    final keyboardUp = keyboardButton != null && media.viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () {
        widget.focusNode.unfocus();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        key: keyboardButton == null ? null : Key("$keyboardUp"),
        backgroundColor: YiviPalette.of(context).background,
        appBar: widget.appBar,
        body: KeyboardAnimationListener(
          key: _scrollableKey,
          onKeyboardSettled: (context, inset, visible) {
            _handleFocusChange();
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SafeArea(
              child: Padding(
                padding: .all(theme.defaultSpacing),
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    SizedBox(height: theme.defaultSpacing),
                    ...widget.before,
                    Container(key: _fieldPositionKey, child: widget.field),
                    ...widget.after,
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonAnimator: .noAnimation,
        floatingActionButton: keyboardUp
            ? Padding(
                padding: .only(
                  left: theme.defaultSpacing + media.padding.left,
                  right: theme.defaultSpacing + media.padding.right,
                ),
                child: keyboardButton,
              )
            : null,
        floatingActionButtonLocation: .centerFloat,
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: keyboardUp ? null : widget.bottomBar,
      ),
    );
  }
}

/// The top of the e-mail and phone screens: a rounded tile with an envelope
/// or a phone, the heading and the explanation, centred.
class ContactIntro extends StatelessWidget {
  final IconData icon;

  /// The colours of the tile: warning (amber) for e-mail, success (green)
  /// for a phone number, as their cards.
  final DialogTone tone;
  final String headerKey;
  final String bodyKey;
  final Map<String, String> bodyParams;

  const ContactIntro({
    super.key,
    required this.icon,
    required this.tone,
    required this.headerKey,
    required this.bodyKey,
    this.bodyParams = const {},
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final (fill, ink) = ToneDisc.colors(palette, tone);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Center(
          child: ExcludeSemantics(
            child: Container(
              width: 88,
              height: 88,
              decoration: ShapeDecoration(
                color: fill,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(YiviCorners.iconTile),
                  ),
                ),
              ),
              child: Icon(icon, size: 44, color: ink),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TranslatedText(
          headerKey,
          isHeader: true,
          textAlign: .center,
          style: palette
              .display(24, weight: FontWeight.w700)
              .copyWith(height: 32 / 24, color: palette.heading),
        ),
        const SizedBox(height: 8),
        TranslatedText(
          bodyKey,
          translationParams: bodyParams,
          textAlign: .center,
          style: palette.body(16).copyWith(height: 24 / 16),
        ),
      ],
    );
  }
}

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
    final palette = YiviPalette.of(context);
    return Padding(
      // Sideways it starts the right column, level with the explanation.
      padding: EdgeInsets.fromLTRB(4, useSheetColumns(context) ? 2 : 28, 4, 8),
      child: TranslatedText(
        labelKey,
        textAlign: textAlign,
        style: palette
            .body(14, weight: FontWeight.w600)
            .copyWith(height: 20 / 14, color: palette.heading),
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
  });

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    // 48 wide, narrower when a long code would not fit.
    PinTheme box(Color border, double width) => PinTheme(
      width: width,
      height: 60,
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
        ContactFieldLabel(labelKey, textAlign: TextAlign.center),
        LayoutBuilder(
          builder: (context, constraints) {
            final fits = (constraints.maxWidth - _gap * (length - 1)) / length;
            final width = fits.isFinite ? fits.clamp(32.0, 48.0) : 48.0;
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
              mainAxisAlignment: .center,
              separatorBuilder: (_) => const SizedBox(width: _gap),
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
              hapticFeedbackType: .lightImpact,
            );
          },
        ),
      ],
    );
  }
}

/// "No email received?": an underlined link-blue text button, centred.
class ContactTextLink extends StatelessWidget {
  final String labelKey;
  final VoidCallback onTap;

  const ContactTextLink({
    super.key,
    required this.labelKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: TextLink(
          label: FlutterI18n.translate(context, labelKey),
          onPressed: onTap,
        ),
      ),
    );
  }
}

/// The error under the code boxes, centred.
class ContactCodeError extends StatelessWidget {
  final String textKey;

  const ContactCodeError(this.textKey, {super.key});

  @override
  Widget build(BuildContext context) => FieldError(
    FlutterI18n.translate(context, textKey),
    align: TextAlign.center,
  );
}
