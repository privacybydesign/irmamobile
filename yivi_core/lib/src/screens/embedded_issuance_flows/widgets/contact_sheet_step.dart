import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/email_code_pointer.dart";
import "../../../models/session.dart";
import "../../../providers/email_issuance_provider.dart";
import "../../../providers/sms_issuance_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/handle_pointer.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../../../widgets/irma_confirmation_dialog.dart";
import "../../../widgets/loading_indicator.dart";
import "../../session/widgets/issue_sheet_progress.dart";
import "../email/widgets/email_address_entry.dart";
import "../sms/widgets/phone_number_entry.dart";
import "contact_widgets.dart";

/// Which contact detail a [ContactSheetStep] adds.
enum ContactKind { email, phone }

/// Step 2 of adding an e-mail address or phone number in a sheet (the Change
/// sheet of a request, or Add data): the address or number, then the code sent to it, as on the
/// full screens (the same fields, the same issuer calls), with the buttons in
/// a row. The checked code starts the issuance through [handlePointer], which
/// hands it to the sheet waiting for it (step 3).
class ContactSheetStep extends ConsumerStatefulWidget {
  final ContactKind kind;

  /// What the progress tag names: the request, or the card being added.
  final IssueSheetSubject subject;

  /// "Cancel": the sheet asks whether to stop adding.
  final VoidCallback onCancel;

  /// Back from entering the address: to the details.
  final VoidCallback onBack;

  const ContactSheetStep({
    super.key,
    required this.kind,
    required this.subject,
    required this.onCancel,
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

  bool get _email => widget.kind == ContactKind.email;

  /// "email_issuance.enter_email" or "sms_issuance.enter_phone", for one
  /// of their [part]s, and the same for the code.
  String _key(String screen, String part) => _email
      ? "email_issuance.${screen == "enter" ? "enter_email" : "verify_code"}.$part"
      : "sms_issuance.${screen == "enter" ? "enter_phone" : "verify_code"}.$part";

  String _t(String key, [Map<String, String>? params]) =>
      FlutterI18n.translate(context, key, translationParams: params);

  String get _language =>
      FlutterI18n.currentLocale(context)?.languageCode ?? "en";

  @override
  void dispose() {
    _focusNode.dispose();
    _codeFocus.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ---------- the two flows, through their providers ----------

  ({_Stage stage, String target, Object error, bool invalidCode}) _read() {
    if (_email) {
      final s = ref.watch(emailIssuanceProvider);
      return (
        stage: switch (s.stage) {
          EmailIssuanceStage.enteringEmail => _Stage.entering,
          EmailIssuanceStage.waiting => _Stage.sending,
          EmailIssuanceStage.enteringVerificationCode => _Stage.code,
        },
        target: s.email,
        error: s.error,
        invalidCode: s.error is EmailIssuanceInvalidCodeError,
      );
    }
    final s = ref.watch(smsIssuanceProvider);
    return (
      stage: switch (s.stage) {
        SmsIssuanceStage.enteringPhoneNumber => _Stage.entering,
        SmsIssuanceStage.waiting => _Stage.sending,
        SmsIssuanceStage.enteringVerificationCode => _Stage.code,
      },
      target: s.phoneNumber,
      error: s.error,
      invalidCode: s.error is SmsIssuanceInvalidCodeError,
    );
  }

  bool _isError(Object error) =>
      error is! EmailIssuanceNoError &&
      error is! SmsIssuanceNoError &&
      error is! EmailIssuanceInvalidCodeError &&
      error is! SmsIssuanceInvalidCodeError;

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
    if (target != null) _send(target);
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
      // A wrong code: empty boxes, ready for another try.
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

  /// Back from the code to the address, as on the full screen: asks first.
  Future<void> _backToEntering() async {
    final back =
        await showDialog<bool>(
          context: context,
          builder: (context) => IrmaConfirmationDialog(
            titleTranslationKey: _key("verify", "back_dialog.title"),
            contentTranslationKey: _key("verify", "back_dialog.body"),
            confirmTranslationKey: _key("verify", "back_dialog.confirm"),
            cancelTranslationKey: _key("verify", "back_dialog.cancel"),
          ),
        ) ??
        false;
    if (!back || !mounted) return;
    _codeController.clear();
    if (_email) {
      ref.read(emailIssuanceProvider.notifier).goBackToEnteringEmail();
    } else {
      ref.read(smsIssuanceProvider.notifier).goBackToEnterPhone();
    }
  }

  Future<void> _askResend(String target) async {
    final resend =
        await showDialog<bool>(
          context: context,
          builder: (context) => IrmaConfirmationDialog(
            titleTranslationKey: _key("verify", "resend_dialog.title"),
            contentTranslationKey: _key("verify", "resend_dialog.body"),
            confirmTranslationKey: _key("verify", "resend_dialog.confirm"),
            cancelTranslationKey: _key("verify", "resend_dialog.cancel"),
          ),
        ) ??
        false;
    if (resend && mounted) {
      _codeController.clear();
      _send(target);
    }
  }

  // ---------- the page ----------

  @override
  Widget build(BuildContext context) {
    final state = _read();
    final palette = YiviPalette.of(context);
    final code = state.stage == _Stage.code;
    final error = _isError(state.error);
    final icon = _email ? Icons.mail_rounded : Icons.smartphone_rounded;
    final tone = _email ? DialogTone.warning : DialogTone.success;

    final Widget body;
    final SheetActionRow bar;
    if (error) {
      body = Container(
        key: const Key("contact_sheet_error"),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: ShapeDecoration(
          color: palette.errorSurface,
          shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        child: Text(
          _t(code ? _key("verify", "error") : _key("enter", "error")),
          style: palette
              .body(14, weight: FontWeight.w600)
              .copyWith(height: 20 / 14, color: palette.errorText),
        ),
      );
      bar = SheetActionRow(
        secondaryLabel: _t(_key("enter", "back_button")),
        onSecondary: widget.onCancel,
        primaryKey: const Key("contact_sheet_retry"),
        primaryLabel: _t("ui.retry"),
        onPrimary: _resetError,
      );
    } else if (state.stage == _Stage.sending) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Center(child: LoadingIndicator()),
      );
      bar = SheetActionRow(
        secondaryLabel: _t(_key("enter", "back_button")),
        onSecondary: widget.onCancel,
        primaryLabel: _t(_key("enter", "next_button")),
      );
    } else if (code) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContactIntro(
            icon: icon,
            tone: tone,
            headerKey: _key("verify", "header"),
            bodyKey: _key("verify", "body"),
            bodyParams: {_email ? "email" : "phone": state.target},
          ),
          ContactCodeField(
            fieldKey: Key(
              _email
                  ? "email_verification_code_input_field"
                  : "sms_verification_code_input_field",
            ),
            controller: _codeController,
            focusNode: _codeFocus,
            length: _email ? emailCodeLength : 6,
            invalid: state.invalidCode,
            smsRetriever: _email ? null : ref.watch(smsRetrieverProvider),
            onChanged: (_) => setState(() {}),
            onCompleted: _verify,
          ),
          if (state.invalidCode)
            ContactCodeError(_key("verify", "invalid_code_error")),
          ContactTextLink(
            labelKey: _email
                ? "email_issuance.verify_code.no_email_received"
                : "sms_issuance.verify_code.no_sms_received",
            onTap: () => _askResend(state.target),
          ),
        ],
      );
      final complete =
          _codeController.text.length == (_email ? emailCodeLength : 6);
      bar = SheetActionRow(
        secondaryKey: const Key("contact_sheet_cancel"),
        secondaryLabel: _t(_key("verify", "back_button")),
        onSecondary: widget.onCancel,
        primaryKey: const Key("contact_sheet_verify"),
        primaryLabel: _t(_key("verify", "next_button")),
        primaryLeading: _verifying ? const _Spinner() : null,
        onPrimary: complete && !_verifying
            ? () => _verify(_codeController.text)
            : null,
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ContactIntro(
            icon: icon,
            tone: tone,
            headerKey: _key("enter", "header"),
            bodyKey: _key("enter", "body"),
          ),
          ContactFieldLabel(_key("enter", "label")),
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
        ],
      );
      bar = SheetActionRow(
        secondaryKey: const Key("contact_sheet_cancel"),
        secondaryLabel: _t(_key("enter", "back_button")),
        onSecondary: widget.onCancel,
        primaryKey: const Key("contact_sheet_send"),
        primaryLabel: _t(_key("enter", "next_button")),
        onPrimary: _valid ? _submitTarget : null,
      );
    }

    return GlassSheetPage(
      title: _t(code ? _key("verify", "title") : _key("enter", "title")),
      onBack: code ? _backToEntering : widget.onBack,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      bottom: bar,
      pinned: IssueSheetProgress(subject: widget.subject, step: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _focusNode.unfocus();
          _codeFocus.unfocus();
        },
        child: body,
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
