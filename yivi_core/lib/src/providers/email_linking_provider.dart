import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/keyshare_email_link_api.dart";
import "../models/session.dart";
import "../util/value_holder.dart";
import "contact_issuance_provider.dart";
import "credentials_provider.dart";
import "local_backends_provider.dart";
import "preferences_provider.dart";

/// Endpoint of the keyshare server that starts the disclosure linking the
/// e-mail address, from privacybydesign/irmago#744. Empty until that endpoint
/// ships and the app is told where it lives; until then only a local backend
/// set in the debug menu has it.
final _keyshareEmailLinkUrlProvider = NotifierProvider(() => ValueHolder(""));

final _keyshareEmailLinkProvider = Provider<String>(
  (ref) =>
      ref.watch(localBackendsProvider)?.keyshareEmailLink ??
      ref.watch(_keyshareEmailLinkUrlProvider),
);

/// Whether an e-mail address can be linked: the keyshare server's link
/// endpoint is known. The enrollment's e-mail step, the banner and the
/// settings entry only show when it is.
final emailLinkingOfferedProvider = Provider<bool>(
  (ref) => ref.watch(_keyshareEmailLinkProvider).isNotEmpty,
);

final keyshareEmailLinkApiProvider = Provider<KeyshareEmailLinkApi>(
  (ref) =>
      DefaultKeyshareEmailLinkApi(url: ref.watch(_keyshareEmailLinkProvider)),
);

/// Whether the e-mail linking flow is available: linking is offered and no
/// address is linked yet. "Finish setting up Yivi" and the settings entry
/// follow it.
final emailLinkAvailableProvider = Provider<bool>((ref) {
  // Not offered: nothing else to know (the preferences are not even read).
  if (!ref.watch(emailLinkingOfferedProvider)) return false;
  return !ref.watch(emailLinkedProvider);
});

/// What the code screen does with the code from a link.
enum EmailLinkHandling {
  /// Fill in the code and wait for a tap on "Code controleren".
  fillIn,

  /// Fill in the code and send it. Only while the user waits for a code for
  /// an address they typed, and the link names no other address: anyone can
  /// send a link with their own address and code. A link without an address
  /// is checked against the typed one, so a code meant for another address
  /// fails.
  submit,
}

class EmailLinkingState {
  /// The disclosure session that shares the address with MijnYivi.
  final int? disclosureSessionId;

  /// The link from the e-mail, waiting for the code screen to pick it up.
  final EmailCodePointer? link;

  /// What to do with [link] once the code screen picks it up.
  final EmailLinkHandling linkHandling;

  const EmailLinkingState({
    this.disclosureSessionId,
    this.link,
    this.linkHandling = .fillIn,
  });
}

/// The link from the e-mail on its way to the linking sheet, and the
/// disclosure that shares the address with MijnYivi, so the session screen
/// knows which one ends in the "linked" screen.
class EmailLinking extends Notifier<EmailLinkingState> {
  @override
  EmailLinkingState build() => const EmailLinkingState();

  void trackDisclosure(int sessionId) {
    state = EmailLinkingState(disclosureSessionId: sessionId);
  }

  Future<SessionPointer> startDisclosure() =>
      ref.read(keyshareEmailLinkApiProvider).startSession();

  void receiveLink(EmailCodePointer link) {
    state = EmailLinkingState(
      link: link,
      linkHandling: _codeRequestedFor(link.email) ? .submit : .fillIn,
    );
  }

  bool _codeRequestedFor(String? email) {
    final provider = contactIssuanceProvider(ContactFlow.linkEmail);
    if (!ref.exists(provider)) return false;

    final flow = ref.read(provider);
    return flow.stage == ContactStage.code &&
        flow.source == ContactSource.typed &&
        (email == null ||
            flow.target.trim().toLowerCase() == email.toLowerCase());
  }

  /// Hands the pending link to the caller exactly once.
  EmailCodePointer? takeLink() {
    final link = state.link;
    if (link == null) return null;
    state = const EmailLinkingState();
    return link;
  }

  Future<void> markLinked() =>
      ref.read(preferencesProvider).emailLinked.set(true);
}

final emailLinkingProvider = NotifierProvider<EmailLinking, EmailLinkingState>(
  EmailLinking.new,
);
