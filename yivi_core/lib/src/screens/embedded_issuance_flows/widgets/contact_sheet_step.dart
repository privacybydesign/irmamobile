import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/email_code_pointer.dart";
import "../../../models/session.dart";
import "../../../providers/email_issuance_provider.dart";
import "../../../providers/sms_issuance_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/after_frame.dart";
import "../../../util/handle_pointer.dart";
import "../../../util/i18n.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/sheet_actions.dart";
import "../../../widgets/glass/sheet_layout.dart";
import "../../../widgets/pill_text_field.dart";
import "../../../widgets/resend_countdown.dart";
import "../../session/widgets/issue_sheet_progress.dart";
import "../email/widgets/email_address_entry.dart";
import "../sms/widgets/phone_number_entry.dart";
import "contact_widgets.dart";

/// Which contact detail a [ContactSheetStep] adds.
enum ContactKind { email, phone }

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
/// Both pages follow the flow's provider; the sheet shows the code page
/// while its stage is the code ([ContactSheetStep.atCode]).
///
/// The same issuer calls as the full screens (`emailIssuanceProvider`,
/// `smsIssuanceProvider`). The checked code starts the issuance through
/// [handlePointer], which hands it to the sheet waiting for it (step 3).
class ContactSheetStep extends ConsumerStatefulWidget {
  final ContactKind kind;

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
    required this.kind,
    required this.subject,
    this.total = 4,
    this.code = false,
    required this.onBack,
  });

  /// Whether [kind]'s flow is at the code, so the sheet shows the code page.
  /// Watches the flow from a build; [watch] false reads it once (a
  /// callback).
  static bool atCode(WidgetRef ref, ContactKind kind, {bool watch = true}) =>
      _stageOf(ref, kind, watch: watch) == _Stage.code;

  /// Back from the code to the address, filled in, to change it.
  static void backToAddress(WidgetRef ref, ContactKind kind) =>
      _Flow.of(kind).back(ref);

  @override
  ConsumerState<ContactSheetStep> createState() => _ContactSheetStepState();
}

/// The stage of either flow, in the terms of this step.
enum _Stage { entering, sending, code }

/// [kind]'s stage: watched from a build, or read once ([watch] false).
_Stage _stageOf(WidgetRef ref, ContactKind kind, {required bool watch}) =>
    _Flow.of(kind).state(ref, watch: watch).stage;

/// What a flow's provider holds, in the terms of this step.
typedef _FlowState = ({_Stage stage, String target, Object error});

/// The e-mail or the SMS flow, through its provider: the one place the two
/// differ in what they call.
sealed class _Flow {
  const _Flow();

  factory _Flow.of(ContactKind kind) =>
      kind == ContactKind.email ? const _EmailFlow() : const _PhoneFlow();

  /// The flow's state: watched from a build, or read once ([watch] false).
  _FlowState state(WidgetRef ref, {required bool watch});

  int get codeLength;

  void send(WidgetRef ref, String target, String language);

  Future<SessionPointer?> verify(WidgetRef ref, String code);

  void resetError(WidgetRef ref);

  /// Back from the code to the address.
  void back(WidgetRef ref);

  /// When a new code can be sent to [target].
  DateTime? resendAt(WidgetRef ref, String target);
}

class _EmailFlow extends _Flow {
  const _EmailFlow();

  static final _p = emailIssuanceProvider;

  @override
  _FlowState state(WidgetRef ref, {required bool watch}) {
    final s = watch ? ref.watch(_p) : ref.read(_p);
    return (
      stage: switch (s.stage) {
        EmailIssuanceStage.enteringEmail => _Stage.entering,
        EmailIssuanceStage.waiting => _Stage.sending,
        EmailIssuanceStage.enteringVerificationCode => _Stage.code,
      },
      target: s.email,
      error: s.error,
    );
  }

  @override
  int get codeLength => emailCodeLength;

  @override
  void send(WidgetRef ref, String target, String language) =>
      ref.read(_p.notifier).sendEmail(email: target, language: language);

  @override
  Future<SessionPointer?> verify(WidgetRef ref, String code) =>
      ref.read(_p.notifier).verifyCode(code: code);

  @override
  void resetError(WidgetRef ref) => ref.read(_p.notifier).resetError();

  @override
  void back(WidgetRef ref) => ref.read(_p.notifier).goBackToEnteringEmail();

  @override
  DateTime? resendAt(WidgetRef ref, String target) =>
      ref.read(_p.notifier).resendAt(target);
}

class _PhoneFlow extends _Flow {
  const _PhoneFlow();

  static final _p = smsIssuanceProvider;

  @override
  _FlowState state(WidgetRef ref, {required bool watch}) {
    final s = watch ? ref.watch(_p) : ref.read(_p);
    return (
      stage: switch (s.stage) {
        SmsIssuanceStage.enteringPhoneNumber => _Stage.entering,
        SmsIssuanceStage.waiting => _Stage.sending,
        SmsIssuanceStage.enteringVerificationCode => _Stage.code,
      },
      target: s.phoneNumber,
      error: s.error,
    );
  }

  @override
  int get codeLength => smsCodeLength;

  @override
  void send(WidgetRef ref, String target, String language) =>
      ref.read(_p.notifier).sendSms(phoneNumber: target, language: language);

  @override
  Future<SessionPointer?> verify(WidgetRef ref, String code) =>
      ref.read(_p.notifier).verifyCode(code: code);

  @override
  void resetError(WidgetRef ref) => ref.read(_p.notifier).resetError();

  @override
  void back(WidgetRef ref) => ref.read(_p.notifier).goBackToEnterPhone();

  @override
  DateTime? resendAt(WidgetRef ref, String target) =>
      ref.read(_p.notifier).resendAt(target);
}

class _ContactSheetStepState extends ConsumerState<ContactSheetStep> {
  final _focusNode = FocusNode();
  final _codeFocus = FocusNode();
  final _codeController = TextEditingController();
  final _emailKey = GlobalKey<EmailAddressEntryState>();
  final _phoneKey = GlobalKey<PhoneNumberEntryState>();

  var _valid = false;
  var _verifying = false;

  /// A new code was sent from the code stage.
  var _sentAgain = false;

  bool get _email => widget.kind == ContactKind.email;

  _Flow get _flow => _Flow.of(widget.kind);

  /// The `contact_sheet.<part>_email` or `_phone` text.
  String _k(String part) =>
      context.tr("contact_sheet.${part}_${_email ? "email" : "phone"}");

  String get _language => context.lang;

  @override
  void initState() {
    super.initState();
    // The keyboard comes up at once: the field is what the page is for.
    afterFrame(() {
      if (widget.code) {
        _codeFocus.requestFocus();
      } else if (_stageNow() == _Stage.entering) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _codeFocus.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ---------- the two flows, through their providers ----------

  /// The stage outside build, where watching is not allowed.
  _Stage _stageNow() => _stageOf(ref, widget.kind, watch: false);

  bool _errorNow() => !_none(_flow.state(ref, watch: false).error);

  static bool _none(Object error) =>
      error is EmailIssuanceNoError || error is SmsIssuanceNoError;

  static bool _wrongCode(Object error) =>
      error is EmailIssuanceInvalidCodeError ||
      error is SmsIssuanceInvalidCodeError;

  void _send(String target) => _flow.send(ref, target, _language);

  void _submitTarget() {
    final target = _email
        ? _emailKey.currentState?.submittable()
        : _phoneKey.currentState?.submittable();
    if (target == null) return;
    _sentAgain = false;
    _send(target);
  }

  Future<void> _verify(String code) async {
    if (_verifying) return;
    setState(() => _verifying = true);
    final session = await _flow.verify(ref, code.toUpperCase());
    if (!mounted) return;
    setState(() => _verifying = false);
    if (session == null) {
      // Not right: empty boxes, ready for another try; the error stays
      // under them until the next character.
      _codeController.clear();
      _codeFocus.requestFocus();
      return;
    }
    await handlePointer(context, session);
  }

  void _resetError() => _flow.resetError(ref);

  /// Back on the address, filled in, to change it: the code page slides
  /// away (the address page under it focuses its field as it comes back).
  void _change() {
    _codeController.clear();
    _sentAgain = false;
    ContactSheetStep.backToAddress(ref, widget.kind);
  }

  void _sendAgain(String target) {
    _codeController.clear();
    setState(() => _sentAgain = true);
    _send(target);
  }

  /// Back from the code is to the address; from the address it leaves the
  /// step for the details.
  void _back() => widget.code ? _change() : widget.onBack();

  /// The address page's field gets the keyboard again when the code page
  /// over it goes (see [GlassSheetPages.isTopPage]).
  bool _wasTop = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final top = GlassSheetPages.isTopPage(context);
    if (!widget.code && top && !_wasTop) {
      afterFrame(() => _focusNode.requestFocus());
    }
    _wasTop = top;
  }

  // ---------- the page ----------

  /// The page's heading ("Your phone number", "Code from the text
  /// message"): in the page, as on every step of adding a card; the bar
  /// names the page once it has scrolled away.
  Widget _heading() {
    final palette = YiviPalette.of(context);
    final sideways = useSheetColumns(context);
    return Padding(
      padding: sideways
          ? const EdgeInsets.only(bottom: 4)
          : const EdgeInsets.fromLTRB(8, 8, 8, 14),
      child: Semantics(
        header: true,
        child: Text(
          _k(widget.code ? "code_head" : "head"),
          key: const Key("contact_sheet_heading"),
          textAlign: sideways ? TextAlign.start : TextAlign.center,
          style: palette
              .display(22, weight: FontWeight.w700)
              .copyWith(height: 30 / 22, color: palette.heading),
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
    final state = _flow.state(ref, watch: true);
    final code = widget.code;
    final atCode = state.stage == _Stage.code;
    final sending = state.stage == _Stage.sending;
    final error = state.error;
    // Each page shows its own errors: the code's on the code page, a code
    // that was not sent on the address page.
    final String? errorText = _none(error) || code != atCode
        ? null
        : code
        ? _wrongCode(error)
              ? context.tr("contact_sheet.wrong_code")
              : context.tr("contact_sheet.not_checked")
        : _k("not_sent");

    final Widget body;
    final SheetAction action;
    if (code) {
      final complete = _codeController.text.length == _flow.codeLength;
      action = SheetAction(
        key: const Key("contact_sheet_verify"),
        label: context.tr("contact_sheet.check_code"),
        busy: _verifying,
        onTap: complete ? () => _verify(_codeController.text) : null,
      );
      final sideways = useSheetColumns(context);
      final resend = ResendCountdown(
        until: _flow.resendAt(ref, state.target),
        builder: (context, left) => ContactResendRow(
          hint: _sentAgain
              ? context.tr("contact_sheet.sent_again")
              : _k("hint"),
          label: left == null
              ? context.tr("contact_sheet.send_again")
              : context.tr("contact_sheet.send_again_in", {"time": left}),
          onTap: left == null ? () => _sendAgain(state.target) : null,
        ),
      );
      body = _split(
        key: const Key("contact_sheet_code"),
        [
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
          if (!sideways) const SizedBox(height: 28),
          ContactCodeField(
            showLabel: false,
            fieldKey: Key(
              _email
                  ? "email_verification_code_input_field"
                  : "sms_verification_code_input_field",
            ),
            labelKey: "contact_sheet.code_label_${_email ? "email" : "phone"}",
            controller: _codeController,
            focusNode: _codeFocus,
            length: _flow.codeLength,
            invalid: errorText != null,
            smsRetriever: _email ? null : ref.watch(smsRetrieverProvider),
            onChanged: (text) {
              // Typing again clears the error; emptying the boxes after a
              // failed check does not.
              if (text.isNotEmpty && _errorNow()) _resetError();
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
              textAlign: useSheetColumns(context)
                  ? TextAlign.start
                  : TextAlign.center,
              style: YiviPalette.of(context).body(15).copyWith(height: 22 / 15),
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
            )
          else
            PhoneNumberEntry(
              key: _phoneKey,
              focusNode: _focusNode,
              onValidChanged: (valid) {
                if (mounted) setState(() => _valid = valid);
              },
              onSubmitted: _submitTarget,
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
    return GlassSheetPage(
      // Left by dragging its header down: no close button.
      closable: false,
      title: context.tr(
        _email
            ? "email_issuance.enter_email.title"
            : "sms_issuance.enter_phone.title",
      ),
      onBack: _back,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      split: landscape,
      action: action,
      // Two steps of their own: the address, then the code.
      titleWidget: IssueRequestorPill.maybe(widget.subject),
      titleWidgetCentred: true,
      titleAfterScroll: 40,
      bottom: IssueSheetProgress(
        subject: widget.subject,
        step: code ? 3 : 2,
        total: widget.total,
      ),
      child: landscape
          ? body
          : Padding(padding: const EdgeInsets.only(top: 8), child: body),
    );
  }
}
