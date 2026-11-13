import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:pinput/pinput.dart";

import "../../../../routing.dart";
import "../../../models/session.dart";
import "../../../theme/theme.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/handle_pointer.dart";
import "../../../util/i18n.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/glass/sheet_layout.dart";
import "../../../widgets/icon_square.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/keyboard_animation_listener.dart";
import "../../../widgets/pill_text_field.dart";
import "../../../widgets/resend_countdown.dart";
import "../../../widgets/surface_card.dart";
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
          onKeyboardSettled: _handleFocusChange,
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

/// The full-screen step where the e-mail address or phone number is typed:
/// the [ContactIntro], the [field] under its label, and "Next" ([nextKey],
/// enabled with [onNext]) with a way back ([backKey]); with the keyboard up
/// only "Next", right above it.
class ContactEnterPage extends StatelessWidget {
  final String titleKey;
  final FocusNode focusNode;
  final double fieldAlignment;
  final IconData icon;
  final DialogTone tone;
  final String headerKey;
  final String bodyKey;
  final String labelKey;
  final Widget field;
  final String nextKey;
  final String backKey;
  final VoidCallback? onNext;

  const ContactEnterPage({
    super.key,
    required this.titleKey,
    required this.focusNode,
    required this.fieldAlignment,
    required this.icon,
    required this.tone,
    required this.headerKey,
    required this.bodyKey,
    required this.labelKey,
    required this.field,
    required this.nextKey,
    required this.backKey,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ContactScrollPage(
      appBar: IrmaAppBar(titleTranslationKey: titleKey),
      focusNode: focusNode,
      fieldAlignment: fieldAlignment,
      before: [
        ContactIntro(
          icon: icon,
          tone: tone,
          headerKey: headerKey,
          bodyKey: bodyKey,
        ),
        ContactFieldLabel(labelKey),
      ],
      field: field,
      keyboardButton: FancyPillButton(
        label: FlutterI18n.translate(context, nextKey),
        onPressed: onNext,
      ),
      bottomBar: IrmaBottomBar(
        primaryButtonLabel: nextKey,
        secondaryButtonLabel: backKey,
        onPrimaryPressed: onNext,
        onSecondaryPressed: context.pop,
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
            child: IconSquare(
              icon: icon,
              fill: fill,
              ink: ink,
              size: 88,
              iconSize: 44,
              radius: YiviCorners.iconTile,
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
    return Padding(
      // Sideways it starts the right column, level with the explanation.
      padding: EdgeInsets.fromLTRB(4, useSheetColumns(context) ? 2 : 28, 4, 8),
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

/// "No email received?": a link-blue text button, centred, 20 below what
/// is above it.
class ContactTextLink extends StatelessWidget {
  final String labelKey;

  /// Shown instead of [labelKey]'s text ("Send again in 0:42").
  final String? label;

  /// Null while it has to wait: dimmed, without an action.
  final VoidCallback? onTap;

  const ContactTextLink({
    super.key,
    required this.labelKey,
    this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: TextLink(
          label: label ?? FlutterI18n.translate(context, labelKey),
          onPressed: onTap,
        ),
      ),
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
    _translated ? _text : FlutterI18n.translate(context, _text),
    align: TextAlign.center,
  );
}

/// While the e-mail or SMS issuer is asked to send the code: a spinner, the
/// step's title ([titleKey]) and a way back ([backKey]).
class ContactWaitingScreen extends StatelessWidget {
  final String titleKey;
  final String backKey;

  const ContactWaitingScreen({
    super.key,
    required this.titleKey,
    required this.backKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: IrmaAppBar(titleTranslationKey: titleKey),
      body: Padding(
        padding: .all(theme.defaultSpacing),
        child: Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: IrmaBottomBar(
        secondaryButtonLabel: backKey,
        onSecondaryPressed: context.pop,
      ),
    );
  }
}

/// Asks the question of [keys] (`$keys.title`, `.body`, `.confirm` and
/// `.cancel`), e.g. whether to go back or to send the code again. True
/// when confirmed.
Future<bool> confirmContactStep(BuildContext context, String keys) =>
    showConfirmDialog(
      context,
      titleKey: "$keys.title",
      messageKey: "$keys.body",
      confirmKey: "$keys.confirm",
      cancelKey: "$keys.cancel",
    );

/// What the e-mail and phone code screens share: the code field's focus and
/// text, the flow started over ([resetFlow]) when the screen is shown again
/// after the one above it closed, and a question before going back or
/// sending again ([confirmThen]).
mixin VerifyCodeScreen<W extends ConsumerStatefulWidget> on ConsumerState<W>
    implements RouteAware {
  final codeFocus = FocusNode();
  final codeController = TextEditingController();

  /// The flow from the start, as the screen is shown again.
  void resetFlow();

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {}

  @override
  void didPopNext() => Future.microtask(resetFlow);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    codeFocus.dispose();
    codeController.dispose();
    super.dispose();
  }

  /// Asks the question of [keys] ([confirmContactStep]) and, when confirmed
  /// while the screen is still there, does [action].
  Future<void> confirmThen(String keys, VoidCallback action) async {
    if (await confirmContactStep(context, keys) && mounted) action();
  }

  /// A code being checked or its issuance starting: a second one would
  /// start a second issuance.
  var _handling = false;

  /// Checks [code] with [verify] and starts the issuance it gives
  /// ([handlePointer]); does nothing while one is under way. The session's
  /// id, or null.
  Future<int?> handleCode(
    String code,
    Future<SessionPointer?> Function(String code) verify,
  ) async {
    if (_handling) return null;
    _handling = true;
    try {
      final session = await verify(code.toUpperCase());
      if (session == null || !mounted) return null;
      return await handlePointer(context, session);
    } finally {
      _handling = false;
    }
  }

  /// A wrong code: empty boxes, focused for another try; [then] before the
  /// focus.
  void clearWrongCode([VoidCallback? then]) {
    codeController.text = "";
    then?.call();
    codeFocus.requestFocus();
  }

  /// [child], where back goes through [goBack] (which asks first).
  Widget backAsks(Future<void> Function() goBack, Widget child) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) goBack();
    },
    child: child,
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
    final (fill, ink) = ToneDisc.colors(
      palette,
      email ? DialogTone.warning : DialogTone.success,
    );
    return SurfaceCard(
      key: const Key("contact_sheet_sent_to"),
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      child: Row(
        spacing: 12,
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
                    style: palette
                        .body(12.5)
                        .copyWith(color: palette.secondaryText),
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
          Semantics(
            button: true,
            child: Material(
              color: palette.tint,
              shape: const StadiumBorder(),
              child: InkWell(
                highlightColor: Colors.transparent,
                key: const Key("contact_sheet_change"),
                customBorder: const StadiumBorder(),
                onTap: onChange,
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 44,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  child: Text(
                    changeLabel,
                    style: palette
                        .body(13, weight: FontWeight.w600)
                        .copyWith(color: palette.link),
                  ),
                ),
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 0),
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
  final String? _hint;
  final String? _linkKey;

  /// A [hint] and "Send again" on one row ([ContactResendRow]).
  const ContactResend.row({
    super.key,
    required this.until,
    required String hint,
    required this.onResend,
  }) : _hint = hint,
       _linkKey = null;

  /// A centred link with [linkKey]'s text ("No email received?",
  /// [ContactTextLink]).
  const ContactResend.link({
    super.key,
    required this.until,
    required String linkKey,
    required this.onResend,
  }) : _linkKey = linkKey,
       _hint = null;

  @override
  Widget build(BuildContext context) {
    return ResendCountdown(
      until: until,
      builder: (context, left) {
        final waiting = left == null
            ? null
            : context.tr("contact_sheet.send_again_in", {"time": left});
        final onTap = left == null ? onResend : null;
        if (_linkKey case final linkKey?) {
          return ContactTextLink(
            labelKey: linkKey,
            label: waiting,
            onTap: onTap,
          );
        }
        return ContactResendRow(
          hint: _hint!,
          label: waiting ?? context.tr("contact_sheet.send_again"),
          onTap: onTap,
        );
      },
    );
  }
}
