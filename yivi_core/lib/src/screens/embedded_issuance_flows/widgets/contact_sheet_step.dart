import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/contact_issuance_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/after_frame.dart";
import "../../../util/handle_pointer.dart";
import "../../../util/i18n.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/sheet_actions.dart";
import "../../../widgets/glass/sheet_layout.dart";
import "../../../widgets/pill_text_field.dart";
import "../../session/widgets/issue_sheet_progress.dart";
import "../email/widgets/email_address_entry.dart";
import "../sms/widgets/phone_number_entry.dart";
import "contact_step_controller.dart";
import "contact_widgets.dart";

/// Steps 2 and 3 of adding an e-mail address or phone number in a sheet (the
/// Change sheet of a request, or Add data), made for a sheet with the
/// keyboard up, as two pages of it: the address or number with a line on
/// what happens ([code] false), and after "Send code" the code boxes under a
/// folded "Code sent to …" row ([code] true), which slides in over it. The
/// code checks itself once it is complete; errors show where they happen.
/// The sheet's close button and back are the way out, so each page has one
/// way on ([SheetAction]): at the bottom on a phone held upright, in the bar
/// elsewhere; the keyboard's return key does the same.
///
/// Both pages follow the flow's provider (`contactIssuanceProvider`); the
/// sheet shows the code page while its stage is the code
/// ([ContactSheetStep.atCode]). The checked code starts the issuance through
/// [handlePointer], which hands it to the sheet waiting for it (step 3).
class ContactSheetStep extends ConsumerStatefulWidget {
  final ContactFlow flow;

  /// What the progress tag names: the request, or the card being added.
  final IssueSheetSubject subject;

  /// The flow's number of steps; the address is step 2, the code step 3.
  final int total;

  /// The code page (step 3); else the address (step 2).
  final bool code;

  /// Back from the address: to the details. (Back from the code is to the
  /// address, filled in.)
  final VoidCallback onBack;

  const ContactSheetStep({
    super.key,
    required this.flow,
    required this.subject,
    required this.total,
    this.code = false,
    required this.onBack,
  });

  /// Whether [flow] is at the code, so the sheet shows the code page.
  /// Watches the flow from a build; [watch] false reads it once (a
  /// callback).
  static bool atCode(WidgetRef ref, ContactFlow flow, {bool watch = true}) =>
      (watch
              ? ref.watch(contactIssuanceProvider(flow))
              : ref.read(contactIssuanceProvider(flow)))
          .stage ==
      ContactStage.code;

  /// Back from the code to the address, filled in, to change it.
  static void backToAddress(WidgetRef ref, ContactFlow flow) =>
      ref.read(contactIssuanceProvider(flow).notifier).backToAddress();

  @override
  ConsumerState<ContactSheetStep> createState() => _ContactSheetStepState();
}

class _ContactSheetStepState extends ConsumerState<ContactSheetStep> {
  final _focusNode = FocusNode();
  late final _c = ContactStepController(() => _flow)
    ..addListener(() {
      if (mounted) setState(() {});
    });
  final _emailKey = GlobalKey<EmailAddressEntryState>();
  final _phoneKey = GlobalKey<PhoneNumberEntryState>();

  var _valid = false;

  bool get _email => widget.flow.kind == ContactKind.email;

  ContactIssuance get _flow =>
      ref.read(contactIssuanceProvider(widget.flow).notifier);

  /// The `contact_sheet.<part>_email` or `_phone` text.
  String _k(String part, [Map<String, String> params = const {}]) =>
      context.tr("contact_sheet.${part}_${_email ? "email" : "phone"}", params);

  String get _language => context.lang;

  @override
  void initState() {
    super.initState();
    // The keyboard comes up at once: the field is what the page is for.
    afterFrame(() {
      if (widget.code) {
        _c.codeFocus.requestFocus();
      } else if (_stateNow().stage == ContactStage.address) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _c.dispose();
    super.dispose();
  }

  // ---------- the flow, through its provider ----------

  /// The state outside build, where watching is not allowed.
  ContactIssuanceState _stateNow() =>
      ref.read(contactIssuanceProvider(widget.flow));

  void _submitTarget() {
    final target = _email
        ? _emailKey.currentState?.submittable()
        : _phoneKey.currentState?.submittable();
    if (target == null) return;
    _c.send(target, _language);
  }

  Future<void> _verify(String code) async {
    final session = await _c.verify(code);
    if (session == null || !mounted) return;
    await handlePointer(context, session);
  }

  /// Back on the address, filled in, to change it: the code page slides
  /// away (the address page under it focuses its field as it comes back).
  void _change() => _c.change();

  /// Back from the code is to the address; from the address it leaves the
  /// step for the details.
  void _back() => widget.code ? _change() : widget.onBack();

  /// The address page's field gets the keyboard again when the code page
  /// over it goes (see [SheetPageInfo.isTop]).
  bool _wasTop = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final top = GlassSheetPages.maybeOf(context)?.isTop ?? true;
    if (!widget.code && top && !_wasTop) {
      afterFrame(() => _focusNode.requestFocus());
    }
    _wasTop = top;
  }

  // ---------- the page ----------

  /// The heading, for the bar's title once it has scrolled under the bar.
  final _headingKey = GlobalKey(debugLabel: "contact_sheet_heading");

  /// The page's heading ("Your phone number", "Code from the text
  /// message"): in the page, at the start, as on every step where you type;
  /// the bar names the page once it has scrolled away.
  Widget _heading() {
    final palette = YiviPalette.of(context);
    final sideways = useSheetColumns(context);
    return Padding(
      padding: sideways
          ? const EdgeInsets.only(bottom: YiviSpace.x4)
          : const EdgeInsets.fromLTRB(
              YiviSpace.x4,
              YiviSpace.x8,
              YiviSpace.x4,
              YiviSpace.x16,
            ),
      child: Semantics(
        header: true,
        child: KeyedSubtree(
          key: _headingKey,
          child: Text(
            _k(widget.code ? "code_head" : "head"),
            key: const Key("contact_sheet_heading"),
            style: sideways
                ? palette.titleCompact.copyWith(color: palette.text)
                : palette.titleStep.copyWith(color: palette.text),
          ),
        ),
      ),
    );
  }

  /// The step's content: [start] above [end]; on a phone held sideways in
  /// two columns, the explanation at the left, the field at the right
  /// ([SheetSplit]). The way on is the page's ([SheetAction]).
  Widget _split(List<Widget> start, List<Widget> end, {Key? key}) {
    start = [_heading(), ...start];
    if (!useSheetColumns(context)) {
      return Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...start, ...end],
      );
    }
    return SheetSplit(
      key: key,
      start: start,
      end: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactIssuanceProvider(widget.flow));
    final code = widget.code;
    final atCode = state.stage == ContactStage.code;
    final sending = state.stage == ContactStage.sending;
    final error = state.error;
    // Each page shows its own errors: the code's on the code page, a code
    // that was not sent on the address page.
    final String? errorText = error == null || code != atCode
        ? null
        : code
        ? error is ContactWrongCode
              ? context.tr("contact_sheet.wrong_code")
              : context.tr("contact_sheet.not_checked")
        : _k("not_sent");

    final Widget body;
    final SheetAction action;
    if (code) {
      final complete = _c.code.text.length == _flow.codeLength;
      action = SheetAction(
        key: const Key("contact_sheet_verify"),
        label: context.tr("contact_sheet.check_code"),
        busy: _c.verifying,
        onTap: complete ? () => _verify(_c.code.text) : null,
      );
      final sideways = useSheetColumns(context);
      final resend = ContactResend.row(
        until: _flow.resendAt(state.target),
        hint: _c.sentAgain
            ? context.tr("contact_sheet.sent_again")
            : _k("hint"),
        onResend: () => _c.sendAgain(state.target, _language),
      );
      body = _split(
        key: const Key("contact_sheet_code"),
        [
          // Held sideways one line under the heading: where it went, and
          // the way to change it.
          if (sideways)
            _SentLine(
              text: _k("sent_short", {"target": state.target}),
              change: context.tr("contact_sheet.change"),
              onChange: _change,
            )
          else
            ContactSentTo(
              label: _k("sent_to"),
              target: state.target,
              email: _email,
              changeLabel: context.tr("contact_sheet.change"),
              onChange: _change,
            ),
        ],
        [
          // The room the label above the boxes had: the heading says what
          // goes in them now.
          if (!sideways) const SizedBox(height: YiviSpace.x24),
          ContactCodeField(
            showLabel: false,
            spread: true,
            boxHeight: sideways ? 56 : 60,
            fieldKey: Key(
              _email
                  ? "email_verification_code_input_field"
                  : "sms_verification_code_input_field",
            ),
            controller: _c.code,
            focusNode: _c.codeFocus,
            length: _flow.codeLength,
            invalid: errorText != null,
            smsRetriever: _email ? null : ref.watch(smsRetrieverProvider),
            onChanged: (text) {
              // Typing again clears the error; emptying the boxes after a
              // failed check does not.
              _c.codeTyped(text, hasError: _stateNow().error != null);
              setState(() {});
            },
            onCompleted: _verify,
          ),
          if (errorText != null)
            KeyedSubtree(
              key: const Key("contact_sheet_error"),
              child: ContactCodeError.text(errorText),
            )
          else
            resend,
        ],
      );
    } else {
      action = SheetAction(
        key: const Key("contact_sheet_send"),
        label: context.tr("contact_sheet.send_code"),
        busy: sending,
        onTap: _valid ? _submitTarget : null,
      );
      body = _split(
        [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: useSheetColumns(context) ? 0 : 4,
            ),
            child: Text(
              _k("intro"),
              style: useSheetColumns(context)
                  ? YiviPalette.of(context).body(14).copyWith(height: 20 / 14)
                  : YiviPalette.of(context).body(15).copyWith(height: 22 / 15),
            ),
          ),
        ],
        [
          ContactFieldLabel(
            _email
                ? "email_issuance.enter_email.label"
                : "sms_issuance.enter_phone.label",
          ),
          if (_email)
            EmailAddressEntry(
              key: _emailKey,
              focusNode: _focusNode,
              onValidChanged: (valid) => setState(() => _valid = valid),
              onSubmitted: _submitTarget,
              initial: _stateNow().target,
            )
          else
            PhoneNumberEntry(
              key: _phoneKey,
              focusNode: _focusNode,
              onValidChanged: (valid) {
                if (mounted) setState(() => _valid = valid);
              },
              onSubmitted: _submitTarget,
              initial: _stateNow().target,
            ),
          if (errorText != null)
            KeyedSubtree(
              key: const Key("contact_sheet_error"),
              child: FieldError(errorText),
            ),
        ],
      );
    }

    final landscape = useSheetColumns(context);
    return landscape
        ? GlassSheetPage.split(
            // Two steps of their own: the address, then the code.
            title: SheetTitle(
              context.tr(
                _email
                    ? "email_issuance.enter_email.title"
                    : "sms_issuance.enter_phone.title",
              ),
              widget: IssueRequestorPill.maybe(widget.subject),
              centred: true,
              reveal: SheetTitleReveal.under(_headingKey),
            ),
            // Left by dragging its header down: no close button.
            exits: SheetExits(onBack: _back, close: SheetClose.none),
            action: action,
            bottomInBar: true,
            bottom: IssueSheetProgress(step: code ? 3 : 2, total: widget.total),
            child: landscape
                ? body
                : Padding(
                    padding: const EdgeInsets.only(top: YiviSpace.x8),
                    child: body,
                  ),
          )
        : GlassSheetPage.scroll(
            // Two steps of their own: the address, then the code.
            title: SheetTitle(
              context.tr(
                _email
                    ? "email_issuance.enter_email.title"
                    : "sms_issuance.enter_phone.title",
              ),
              widget: IssueRequestorPill.maybe(widget.subject),
              centred: true,
              reveal: SheetTitleReveal.under(_headingKey),
            ),
            // Left by dragging its header down: no close button.
            exits: SheetExits(onBack: _back, close: SheetClose.none),
            padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
            action: action,
            bottom: IssueSheetProgress(step: code ? 3 : 2, total: widget.total),
            child: landscape
                ? body
                : Padding(
                    padding: const EdgeInsets.only(top: YiviSpace.x8),
                    child: body,
                  ),
          );
  }
}

/// Held sideways, under the code's heading: "Texted to {number} · Change".
class _SentLine extends StatelessWidget {
  final String text;
  final String change;
  final VoidCallback onChange;

  const _SentLine({
    required this.text,
    required this.change,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final style = palette
        .body(14)
        .copyWith(height: 20 / 14, color: palette.heading);
    return Wrap(
      key: const Key("contact_sheet_sent_to"),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text("$text · ", style: style),
        Semantics(
          button: true,
          child: GestureDetector(
            key: const Key("contact_sheet_change"),
            behavior: HitTestBehavior.opaque,
            onTap: onChange,
            child: Text(
              change,
              style: style.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.link,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
