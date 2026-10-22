import "dart:async";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/email_code_pointer.dart";
import "../../../models/session.dart";
import "../../../providers/email_issuance_provider.dart";
import "../../../providers/email_linking_provider.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/pill_text_field.dart";
import "../../embedded_issuance_flows/email/widgets/email_address_entry.dart";
import "../../embedded_issuance_flows/widgets/contact_sheet_step.dart";
import "../../embedded_issuance_flows/widgets/contact_widgets.dart";
import "../widgets/enrollment_page.dart";
import "enrollment_email_link.dart";

/// The optional enrollment step that links an e-mail address to the app, so
/// the user can log in to MijnYivi and block the app from there. It works
/// like adding an e-mail address: the address, Send code, then the code from
/// the e-mail, which checks itself. The checked code issues the address and
/// links it in MijnYivi ([runOwnSession]), with the PIN of this enrollment.
///
/// Skip, at the top right, goes on without an address; the banner on the
/// Data tab offers it again later.
class EnrollmentEmailScreen extends ConsumerStatefulWidget {
  final String stepLabel;

  /// The account, made in the background since the PIN was confirmed: null
  /// once it is there, else the error. The code is only sent once it is.
  final Future<SessionError?> Function() account;

  /// The PIN of this enrollment, for the two sessions.
  final String pin;

  /// Skipped, or linked.
  final VoidCallback onDone;

  /// The account could not be made.
  final ValueChanged<SessionError> onAccountFailed;

  const EnrollmentEmailScreen({
    super.key,
    required this.stepLabel,
    required this.account,
    required this.pin,
    required this.onDone,
    required this.onAccountFailed,
  });

  @override
  ConsumerState<EnrollmentEmailScreen> createState() =>
      _EnrollmentEmailScreenState();
}

/// Where the code check is.
enum _Check { idle, checking, linked, failed }

class _EnrollmentEmailScreenState extends ConsumerState<EnrollmentEmailScreen> {
  final _emailFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _codeController = TextEditingController();
  final _emailKey = GlobalKey<EmailAddressEntryState>();
  StreamSubscription<Pointer?>? _links;

  var _valid = false;
  var _waitingForAccount = false;
  var _sentAgain = false;
  var _check = _Check.idle;

  /// The address is issued; only linking it in MijnYivi is left to retry.
  var _issued = false;

  String _t(String key) => FlutterI18n.translate(context, key);

  String get _language =>
      FlutterI18n.currentLocale(context)?.languageCode ?? "en";

  @override
  void initState() {
    super.initState();
    // The link in the e-mail, tapped while this step shows, fills in the
    // code here instead of opening the linking screens later.
    final repo = ref.read(irmaRepositoryProvider);
    _links = repo.getPendingPointer().listen((pointer) {
      if (pointer is! EmailCodePointer) return;
      repo.setPendingPointer(null);
      _applyLink(pointer);
    });
  }

  @override
  void dispose() {
    _links?.cancel();
    _emailFocus.dispose();
    _codeFocus.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _applyLink(EmailCodePointer link) {
    if (!mounted || _check != _Check.idle) return;
    final flow = ref.read(emailIssuanceProvider);
    if (flow.stage != EmailIssuanceStage.enteringVerificationCode) return;
    // Anyone can send a link with their own address: only a code for the
    // address typed here is used.
    final email = link.email;
    if (email != null && email.toLowerCase() != flow.email.toLowerCase()) {
      return;
    }
    _codeController.text = link.code;
    _verify(link.code);
  }

  Future<void> _send() async {
    final email = _emailKey.currentState?.submittable();
    if (email == null) return;
    setState(() => _waitingForAccount = true);
    final error = await widget.account();
    if (!mounted) return;
    setState(() => _waitingForAccount = false);
    if (error != null) {
      widget.onAccountFailed(error);
      return;
    }
    _sentAgain = false;
    await ref
        .read(emailIssuanceProvider.notifier)
        .sendEmail(email: email, language: _language);
    if (!mounted) return;
    if (ref.read(emailIssuanceProvider).stage ==
        EmailIssuanceStage.enteringVerificationCode) {
      _codeFocus.requestFocus();
    }
  }

  Future<void> _verify(String code) async {
    if (_check == _Check.checking) return;
    setState(() => _check = _Check.checking);
    final issuance = await ref
        .read(emailIssuanceProvider.notifier)
        .verifyCode(code: code.toUpperCase());
    if (!mounted) return;
    if (issuance == null) {
      // Not right: empty boxes, ready for another try; the error stays under
      // them until the next character.
      setState(() => _check = _Check.idle);
      _codeController.clear();
      _codeFocus.requestFocus();
      return;
    }
    await _link(issuance);
  }

  /// Issues the address (unless that already worked) and links it in
  /// MijnYivi.
  Future<void> _link(SessionPointer? issuance) async {
    setState(() => _check = _Check.checking);
    final repo = ref.read(irmaRepositoryProvider);
    try {
      if (!_issued && issuance != null) {
        await runOwnSession(repo, issuance, pin: widget.pin);
        _issued = true;
      }
      final disclosure = await ref
          .read(keyshareEmailLinkApiProvider)
          .startSession();
      await runOwnSession(repo, disclosure, pin: widget.pin);
      await ref.read(emailLinkingProvider.notifier).markLinked();
    } catch (_) {
      if (mounted) setState(() => _check = _Check.failed);
      return;
    }
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _check = _Check.linked);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) widget.onDone();
  }

  /// After a failed link: link again when the address was issued, else
  /// back to the code to get a new one.
  void _tryAgain() {
    if (_issued) {
      _link(null);
      return;
    }
    setState(() => _check = _Check.idle);
    _change();
  }

  void _change() {
    _codeController.clear();
    _sentAgain = false;
    ref.read(emailIssuanceProvider.notifier).goBackToEnteringEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emailFocus.requestFocus();
    });
  }

  void _sendAgain(String email) {
    _codeController.clear();
    setState(() => _sentAgain = true);
    ref
        .read(emailIssuanceProvider.notifier)
        .sendEmail(email: email, language: _language);
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(emailIssuanceProvider);
    final palette = YiviPalette.of(context);
    final tablet = enrollmentTablet(context);
    final sideways = enrollmentSideways(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final code = flow.stage == EmailIssuanceStage.enteringVerificationCode;
    final sending =
        _waitingForAccount || flow.stage == EmailIssuanceStage.waiting;
    final busy = _check == _Check.checking || _check == _Check.linked;
    final error = flow.error;
    final hasError = error is! EmailIssuanceNoError;
    final align = sideways ? TextAlign.start : TextAlign.center;

    // With the keyboard up a phone has little room: the tile goes, and held
    // sideways the step and the explanation too, with Send code next to
    // the field.
    final compactPhone = keyboard && !tablet;
    final showStep = !(compactPhone && sideways);
    final showLead = !(keyboard && sideways);
    final inlineSend = compactPhone && sideways;

    final tileSize = tablet ? 96.0 : 88.0;
    final (fill, ink) = ToneDisc.colors(palette, DialogTone.warning);
    final about = compactPhone
        ? null
        : Center(
            child: ExcludeSemantics(
              child: Container(
                width: tileSize,
                height: tileSize,
                decoration: ShapeDecoration(
                  color: fill,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(YiviCorners.iconTile),
                    ),
                  ),
                ),
                child: Icon(Icons.mail_rounded, size: 46, color: ink),
              ),
            ),
          );

    final pillSize = tablet ? PillSize.large : PillSize.regular;
    final spinner = const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
    );
    final sendButton = FancyPillButton(
      key: const Key("enrollment_email_send"),
      label: _t("contact_sheet.send_code"),
      size: pillSize,
      leading: sending ? spinner : null,
      onPressed: _valid && !sending ? _send : null,
    );

    final List<Widget> stage;
    if (!code) {
      stage = [
        const ContactFieldLabel("email_issuance.enter_email.label"),
        if (inlineSend)
          Row(
            spacing: 8,
            children: [
              Expanded(child: _field()),
              SizedBox(width: 160, child: sendButton),
            ],
          )
        else
          _field(),
        if (hasError) FieldError(_t("contact_sheet.not_sent_email")),
        if (!inlineSend) ...[const SizedBox(height: 16), sendButton],
      ];
    } else {
      final String? codeError = switch (_check) {
        _Check.failed => _t("enrollment.email_step.not_linked"),
        _ when error is EmailIssuanceInvalidCodeError => _t(
          "contact_sheet.wrong_code",
        ),
        _ when hasError => _t("contact_sheet.not_checked"),
        _ => null,
      };
      stage = [
        const SizedBox(height: 4),
        ContactSentTo(
          label: _t("contact_sheet.sent_to_email"),
          target: flow.email,
          email: true,
          changeLabel: _t("contact_sheet.change"),
          onChange: busy ? () {} : _change,
        ),
        ContactCodeField(
          fieldKey: const Key("email_verification_code_input_field"),
          labelKey: "contact_sheet.code_label_email",
          controller: _codeController,
          focusNode: _codeFocus,
          length: emailCodeLength,
          invalid: codeError != null,
          onChanged: (text) {
            if (text.isNotEmpty && hasError) {
              ref.read(emailIssuanceProvider.notifier).resetError();
            }
            setState(() {});
          },
          onCompleted: _verify,
        ),
        switch (_check) {
          _Check.checking => const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
          _Check.linked => Padding(
            key: const Key("enrollment_email_linked"),
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _t("email_linking.done.title"),
                textAlign: TextAlign.center,
                style: palette
                    .body(15, weight: FontWeight.w700)
                    .copyWith(color: palette.successText),
              ),
            ),
          ),
          _Check.failed => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldError(codeError!, align: TextAlign.center),
              const SizedBox(height: 8),
              PillButton(
                key: const Key("enrollment_email_try_again"),
                label: _t("enrollment.email_step.try_again"),
                style: PillStyle.outlined,
                size: pillSize,
                onPressed: _tryAgain,
              ),
            ],
          ),
          _Check.idle when codeError != null => FieldError(
            codeError,
            align: TextAlign.center,
          ),
          _Check.idle => ContactResendRow(
            hint: _t(
              _sentAgain
                  ? "contact_sheet.sent_again"
                  : "contact_sheet.hint_email",
            ),
            label: _t("contact_sheet.send_again"),
            onTap: () => _sendAgain(flow.email),
          ),
        },
      ];
    }

    final action = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showStep) ...[
          EnrollmentStepLabel(widget.stepLabel),
          const SizedBox(height: 6),
        ],
        EnrollmentTitle(
          code
              ? "enrollment.email_step.code_title"
              : "enrollment.email_step.title",
          textAlign: align,
        ),
        if (showLead) ...[
          const SizedBox(height: 8),
          EnrollmentLead(
            code
                ? "enrollment.email_step.code_body"
                : "enrollment.email_step.body",
            textAlign: align,
          ),
        ],
        ...stage,
      ],
    );

    return EnrollmentPage(
      about: about,
      action: action,
      trailing: busy
          ? null
          : EnrollmentBarTextButton(
              key: const Key("enrollment_email_skip"),
              label: _t("enrollment.email_step.skip"),
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                widget.onDone();
              },
            ),
    );
  }

  Widget _field() => EmailAddressEntry(
    key: _emailKey,
    focusNode: _emailFocus,
    onValidChanged: (valid) => setState(() => _valid = valid),
  );
}
