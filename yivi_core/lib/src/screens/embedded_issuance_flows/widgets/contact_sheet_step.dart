import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/email_code_pointer.dart";
import "../../../models/session.dart";
import "../../../providers/email_issuance_provider.dart";
import "../../../providers/sms_issuance_provider.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/handle_pointer.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../../../widgets/pill_text_field.dart";
import "../../session/widgets/issue_sheet_progress.dart";
import "../email/widgets/email_address_entry.dart";
import "../sms/widgets/phone_number_entry.dart";
import "contact_widgets.dart";

/// Which contact detail a [ContactSheetStep] adds.
enum ContactKind { email, phone }

/// Step 2 of adding an e-mail address or phone number in a sheet (the Change
/// sheet of a request, or Add data), made for a sheet with the keyboard up:
/// one page with a line on what happens, the address or number, and after
/// "Send code" the code boxes under a folded "Code sent to …" row. The code
/// checks itself once it is complete; errors show where they happen. The
/// sheet's close button and back are the way out, so there is one button.
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

  /// Back: to the details.
  final VoidCallback onBack;

  const ContactSheetStep({
    super.key,
    required this.kind,
    required this.subject,
    this.total = 4,
    required this.onBack,
  });

  @override
  ConsumerState<ContactSheetStep> createState() => _ContactSheetStepState();
}

/// The stage of either flow, in the terms of this step.
enum _Stage { entering, sending, code }

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

  /// The `contact_sheet.<part>_email` or `_phone` text.
  String _k(String part) =>
      _t("contact_sheet.${part}_${_email ? "email" : "phone"}");

  String _t(String key, [Map<String, String>? params]) =>
      FlutterI18n.translate(context, key, translationParams: params);

  String get _language =>
      FlutterI18n.currentLocale(context)?.languageCode ?? "en";

  @override
  void initState() {
    super.initState();
    // The keyboard comes up at once: the field is what the page is for.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _stageNow() == _Stage.entering) {
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

  ({_Stage stage, String target, Object error}) _read() {
    if (_email) {
      final s = ref.watch(emailIssuanceProvider);
      return (stage: _emailStage(s.stage), target: s.email, error: s.error);
    }
    final s = ref.watch(smsIssuanceProvider);
    return (stage: _smsStage(s.stage), target: s.phoneNumber, error: s.error);
  }

  /// The stage outside build, where watching is not allowed.
  _Stage _stageNow() => _email
      ? _emailStage(ref.read(emailIssuanceProvider).stage)
      : _smsStage(ref.read(smsIssuanceProvider).stage);

  static _Stage _emailStage(EmailIssuanceStage s) => switch (s) {
    EmailIssuanceStage.enteringEmail => _Stage.entering,
    EmailIssuanceStage.waiting => _Stage.sending,
    EmailIssuanceStage.enteringVerificationCode => _Stage.code,
  };

  static _Stage _smsStage(SmsIssuanceStage s) => switch (s) {
    SmsIssuanceStage.enteringPhoneNumber => _Stage.entering,
    SmsIssuanceStage.waiting => _Stage.sending,
    SmsIssuanceStage.enteringVerificationCode => _Stage.code,
  };

  bool _errorNow() => !_none(
    _email
        ? ref.read(emailIssuanceProvider).error
        : ref.read(smsIssuanceProvider).error,
  );

  static bool _none(Object error) =>
      error is EmailIssuanceNoError || error is SmsIssuanceNoError;

  static bool _wrongCode(Object error) =>
      error is EmailIssuanceInvalidCodeError ||
      error is SmsIssuanceInvalidCodeError;

  void _send(String target) {
    if (_email) {
      ref
          .read(emailIssuanceProvider.notifier)
          .sendEmail(email: target, language: _language);
    } else {
      ref
          .read(smsIssuanceProvider.notifier)
          .sendSms(phoneNumber: target, language: _language);
    }
  }

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
    final SessionPointer? session = _email
        ? await ref
              .read(emailIssuanceProvider.notifier)
              .verifyCode(code: code.toUpperCase())
        : await ref
              .read(smsIssuanceProvider.notifier)
              .verifyCode(code: code.toUpperCase());
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

  void _resetError() {
    if (_email) {
      ref.read(emailIssuanceProvider.notifier).resetError();
    } else {
      ref.read(smsIssuanceProvider.notifier).resetError();
    }
  }

  /// Back on the address, filled in, to change it.
  void _change() {
    _codeController.clear();
    _sentAgain = false;
    if (_email) {
      ref.read(emailIssuanceProvider.notifier).goBackToEnteringEmail();
    } else {
      ref.read(smsIssuanceProvider.notifier).goBackToEnterPhone();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _sendAgain(String target) {
    _codeController.clear();
    setState(() => _sentAgain = true);
    _send(target);
  }

  /// Back leaves the step for the details; coming back starts at the
  /// address again.
  void _back() {
    if (_stageNow() == _Stage.code) _change();
    widget.onBack();
  }

  // ---------- the page ----------

  /// The step's content: [start] above [end] (the buttons under the
  /// page); on a phone held sideways in two columns, the explanation and
  /// [bar] at the left, the field at the right ([SheetSplit]).
  Widget _split(
    List<Widget> start,
    List<Widget> end, {
    required Widget bar,
    Key? key,
  }) {
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
      actions: bar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _read();
    final code = state.stage == _Stage.code;
    final sending = state.stage == _Stage.sending;
    final error = state.error;
    final String? errorText = _none(error)
        ? null
        : code
        ? _wrongCode(error)
              ? _t("contact_sheet.wrong_code")
              : _t("contact_sheet.not_checked")
        : _k("not_sent");

    final Widget body;
    final SheetActionRow bar;
    if (code) {
      final complete =
          _codeController.text.length == (_email ? emailCodeLength : 6);
      bar = SheetActionRow(
        primaryKey: const Key("contact_sheet_verify"),
        primaryLabel: _t("contact_sheet.check_code"),
        primaryLeading: _verifying ? const _Spinner() : null,
        onPrimary: complete && !_verifying
            ? () => _verify(_codeController.text)
            : null,
      );
      body = _split(
        key: const Key("contact_sheet_code"),
        bar: bar,
        [
          ContactSentTo(
            label: _k("sent_to"),
            target: state.target,
            email: _email,
            changeLabel: _t("contact_sheet.change"),
            onChange: _change,
          ),
        ],
        [
          ContactCodeField(
            fieldKey: Key(
              _email
                  ? "email_verification_code_input_field"
                  : "sms_verification_code_input_field",
            ),
            labelKey: "contact_sheet.code_label_${_email ? "email" : "phone"}",
            controller: _codeController,
            focusNode: _codeFocus,
            length: _email ? emailCodeLength : 6,
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
              child: FieldError(errorText, align: TextAlign.center),
            )
          else
            ContactResendRow(
              hint: _sentAgain ? _t("contact_sheet.sent_again") : _k("hint"),
              label: _t("contact_sheet.send_again"),
              onTap: () => _sendAgain(state.target),
            ),
        ],
      );
    } else {
      bar = SheetActionRow(
        primaryKey: const Key("contact_sheet_send"),
        primaryLabel: _t("contact_sheet.send_code"),
        primaryLeading: sending ? const _Spinner() : null,
        onPrimary: _valid && !sending ? _submitTarget : null,
      );
      body = _split(
        bar: bar,
        [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _k("intro"),
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
            )
          else
            PhoneNumberEntry(
              key: _phoneKey,
              focusNode: _focusNode,
              onValidChanged: (valid) {
                if (mounted) setState(() => _valid = valid);
              },
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
      title: _t(
        _email
            ? "email_issuance.enter_email.title"
            : "sms_issuance.enter_phone.title",
      ),
      onBack: _back,
      padding: landscape
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16),
      // Sideways the buttons are in the left column, above the keyboard.
      bottom: landscape ? null : bar,
      scrolls: !landscape,
      childClearsBottom: landscape,
      // Two steps of their own: the address, then the code.
      pinned: IssueSheetProgress(
        subject: widget.subject,
        step: code ? 3 : 2,
        total: widget.total,
      ),
      subtitle: IssueSheetRequestorLine(subject: widget.subject),
      child: landscape
          ? body
          : Padding(padding: const EdgeInsets.only(top: 8), child: body),
    );
  }
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
    return Container(
      key: const Key("contact_sheet_sent_to"),
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YiviCorners.card)),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        spacing: 12,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 36,
              height: 36,
              decoration: ShapeDecoration(
                color: fill,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              child: Icon(
                email ? Icons.mail_rounded : Icons.smartphone_rounded,
                size: 20,
                color: ink,
              ),
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
  final VoidCallback onTap;

  const ContactResendRow({
    required this.hint,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 0),
      child: Row(
        // Sideways on one line: the link right after the hint.
        spacing: useSheetColumns(context) ? 16 : 0,
        children: [
          Flexible(
            fit: useSheetColumns(context) ? FlexFit.loose : FlexFit.tight,
            child: Semantics(
              liveRegion: true,
              child: Text(
                hint,
                style: palette
                    .body(13.5)
                    .copyWith(color: palette.secondaryText),
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

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 18,
    child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFFFFFFF)),
  );
}
