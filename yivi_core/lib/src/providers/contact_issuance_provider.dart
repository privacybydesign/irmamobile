import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:pinput/pinput.dart";

import "../data/contact_issuer_api.dart";
import "../models/session.dart";
import "contact_issuer_api_provider.dart";
import "resend_wait.dart";

export "../data/contact_issuer_api.dart";

/// The number of digits in the code the SMS issuer sends.
const smsCodeLength = 6;

/// Reads the code from an incoming SMS (Android); null elsewhere.
final smsRetrieverProvider = Provider<SmsRetriever?>((ref) => null);

/// Which flow adds a contact detail.
enum ContactFlow {
  /// An e-mail address, in the Add data or Change sheet.
  email(ContactKind.email),

  /// A phone number, in the Add data or Change sheet.
  phone(ContactKind.phone),

  /// The address linked to the keyshare server: the linking screens and
  /// the enrollment step.
  linkEmail(ContactKind.email);

  const ContactFlow(this.kind);
  final ContactKind kind;

  bool get linking => this == linkEmail;
}

/// Where adding the address or number is.
enum ContactStage {
  /// Typing it.
  address,

  /// Asking the issuer to send a code.
  sending,

  /// Waiting for the code.
  code,
}

/// Where the code comes from.
enum ContactSource {
  /// The user typed the address and asked for a code.
  typed,

  /// The link in the e-mail carried the address: the user never asked for
  /// a code for it here.
  link,
}

@immutable
class ContactIssuanceState {
  const ContactIssuanceState({
    this.stage = ContactStage.address,
    this.target = "",
    this.source = ContactSource.typed,
    this.error,
  });

  final ContactStage stage;

  /// The address or number.
  final String target;
  final ContactSource source;

  /// What went wrong last; null when nothing did.
  final ContactError? error;
}

final contactIssuanceProvider = NotifierProvider.autoDispose
    .family<ContactIssuance, ContactIssuanceState, ContactFlow>(
      ContactIssuance.new,
    );

/// Adding an e-mail address or a phone number: sending a code to it and
/// checking the code, through the flow's issuer.
class ContactIssuance extends Notifier<ContactIssuanceState> {
  ContactIssuance(this.flow);

  final ContactFlow flow;

  /// When each address last got a code: here, not in the state, which a
  /// send replaces.
  late final _wait = ResendWait(ref.read(resendClockProvider));

  ContactIssuerApi get _api => ref.read(
    flow.kind == ContactKind.email
        ? emailIssuerApiProvider
        : smsIssuerApiProvider,
  );

  int get codeLength =>
      flow.kind == ContactKind.email ? emailCodeLength : smsCodeLength;

  @override
  ContactIssuanceState build() => const ContactIssuanceState();

  /// When [target] can get a code again; null when it can now.
  DateTime? resendAt(String target) => _wait.resendAt(target);

  /// Sends a code to [target]. The same target again within the minute:
  /// nothing is sent. A send that fails does not count.
  Future<void> send(String target, {required String language}) async {
    if (!_wait.trySend(target)) return;
    state = ContactIssuanceState(stage: ContactStage.sending, target: target);
    try {
      await _api.send(target: target, language: language);
      if (!ref.mounted) return;
      state = ContactIssuanceState(stage: ContactStage.code, target: target);
    } catch (e) {
      _wait.failed(target);
      if (!ref.mounted) return;
      state = ContactIssuanceState(target: target, error: _errorOf(e));
    }
  }

  /// The session for the right [code]; null when it is not, with the error
  /// set and still at the code.
  Future<SessionPointer?> verify(String code) async {
    final target = state.target;
    final source = state.source;
    try {
      return await _api.verify(target: target, code: code);
    } catch (e) {
      if (ref.mounted) {
        state = ContactIssuanceState(
          stage: ContactStage.code,
          target: target,
          source: source,
          error: _errorOf(e),
        );
      }
      return null;
    }
  }

  /// A code already on its way to [target], as when the link in the e-mail
  /// opens the app: no send.
  void codeOnItsWay(String target) => state = ContactIssuanceState(
    stage: ContactStage.code,
    target: target,
    source: ContactSource.link,
  );

  void clearError() => state = ContactIssuanceState(
    stage: state.stage,
    target: state.target,
    source: state.source,
  );

  /// Back to typing the address or number, the one typed before kept.
  void backToAddress() =>
      state = ContactIssuanceState(target: state.target, source: state.source);

  /// Back to the start, as when the full-screen linking flow's code screen
  /// shows again after a page above it closed.
  void reset() => state = const ContactIssuanceState();

  static ContactError _errorOf(Object e) =>
      e is ContactError ? e : ContactFailed(e);
}
