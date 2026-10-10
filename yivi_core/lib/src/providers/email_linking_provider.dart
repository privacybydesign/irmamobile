import "dart:async";
import "dart:convert";
import "dart:io" show HttpStatus;

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart" as http;

import "../data/feature_flags.dart";
import "../models/email_code_pointer.dart";
import "../models/session.dart";
import "./provider_helpers.dart" as helpers;
import "email_issuance_provider.dart";
import "feature_flag_provider.dart";
import "preferences_provider.dart";

/// How long "Vraag het me later" hides the banner.
const emailBannerSnoozeDuration = Duration(days: 7);

/// Endpoint of the keyshare server that starts the disclosure linking the
/// e-mail address, from privacybydesign/irmago#744. Empty until that endpoint
/// ships and the app is told where it lives.
final keyshareEmailLinkUrlProvider = NotifierProvider(
  () => helpers.ValueNotifier(""),
);

final keyshareEmailLinkApiProvider = Provider<KeyshareEmailLinkApi>(
  (ref) =>
      DefaultKeyshareEmailLinkApi(url: ref.watch(keyshareEmailLinkUrlProvider)),
);

abstract class KeyshareEmailLinkApi {
  /// Starts the disclosure session in which the user shares the issued e-mail
  /// address with MijnYivi, so the keyshare server can link it to this app.
  Future<SessionPointer> startSession();
}

class KeyshareEmailLinkUnavailable implements Exception {
  @override
  String toString() => "The keyshare e-mail link endpoint is not configured";
}

class DefaultKeyshareEmailLinkApi implements KeyshareEmailLinkApi {
  final String url;

  DefaultKeyshareEmailLinkApi({required this.url});

  @override
  Future<SessionPointer> startSession() async {
    if (url.isEmpty) throw KeyshareEmailLinkUnavailable();

    final response = await http.post(Uri.parse(url));
    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        "Starting the e-mail link failed: ${response.statusCode} ${response.body}",
      );
    }

    final pointer = SessionPointer.fromJson(
      jsonDecode(response.body)["sessionPtr"],
    );
    pointer.continueOnSecondDevice = true;
    return pointer;
  }
}

final _emailLinkedProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).getEmailLinked(),
);

final _emailBannerDismissedProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).getEmailBannerDismissed(),
);

final _emailBannerSnoozedUntilProvider = StreamProvider<DateTime>(
  (ref) => ref.watch(preferencesProvider).getEmailBannerSnoozedUntil(),
);

/// Whether the e-mail linking flow is available: the flag is on and no address
/// is linked yet. The banner and the settings entry both follow it.
final emailLinkAvailableProvider = Provider<bool>((ref) {
  final flagOn =
      ref.watch(featureFlagProvider(FeatureFlag.emailLinking)).value ?? false;
  final linked = ref.watch(_emailLinkedProvider).value ?? true;
  return flagOn && !linked;
});

/// Whether the banner on the Gegevens tab shows. It stays hidden until every
/// preference has loaded, so it never flashes up for a user who dismissed it.
final emailBannerVisibleProvider = Provider<bool>((ref) {
  if (!ref.watch(emailLinkAvailableProvider)) return false;

  final dismissed = ref.watch(_emailBannerDismissedProvider).value ?? true;
  final snoozedUntil = ref.watch(_emailBannerSnoozedUntilProvider).value;
  if (dismissed || snoozedUntil == null) return false;

  final snoozeLeft = snoozedUntil.difference(DateTime.now());
  if (snoozeLeft <= Duration.zero) return true;

  // No preference changes when the snooze ends, so recompute then.
  final timer = Timer(snoozeLeft, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return false;
});

class EmailLinkingState {
  /// The e-mail issuance session that has to finish before the keyshare
  /// disclosure starts.
  final int? issuanceSessionId;

  /// The disclosure session that shares the address with MijnYivi.
  final int? disclosureSessionId;

  /// The link from the e-mail, waiting for the code screen to pick it up.
  final EmailCodePointer? link;

  /// Whether [link] is for the address the user already asked a code for in
  /// the open flow. Only then may the code be sent without a tap: anyone can
  /// send a link with their own address and code.
  final bool linkMatchesFlow;

  const EmailLinkingState({
    this.issuanceSessionId,
    this.disclosureSessionId,
    this.link,
    this.linkMatchesFlow = false,
  });
}

/// Tracks the sessions of the e-mail linking flow, so the session screen knows
/// which issuance leads into the keyshare disclosure and which disclosure ends
/// in the "linked" screen.
class EmailLinking extends Notifier<EmailLinkingState> {
  @override
  EmailLinkingState build() => const EmailLinkingState();

  void trackIssuance(int sessionId) {
    state = EmailLinkingState(
      issuanceSessionId: sessionId,
      link: state.link,
      linkMatchesFlow: state.linkMatchesFlow,
    );
  }

  void trackDisclosure(int sessionId) {
    state = EmailLinkingState(disclosureSessionId: sessionId);
  }

  Future<SessionPointer> startDisclosure() =>
      ref.read(keyshareEmailLinkApiProvider).startSession();

  void receiveLink(EmailCodePointer link) {
    state = EmailLinkingState(
      issuanceSessionId: state.issuanceSessionId,
      link: link,
      linkMatchesFlow: _codeRequestedFor(link.email),
    );
  }

  bool _codeRequestedFor(String email) {
    if (!ref.exists(emailIssuanceProvider)) return false;

    final flow = ref.read(emailIssuanceProvider);
    return flow.stage == EmailIssuanceStage.enteringVerificationCode &&
        flow.email.trim().toLowerCase() == email.toLowerCase();
  }

  /// Hands the pending link to the caller exactly once.
  EmailCodePointer? takeLink() {
    final link = state.link;
    if (link == null) return null;
    state = EmailLinkingState(issuanceSessionId: state.issuanceSessionId);
    return link;
  }

  Future<void> markLinked() => ref.read(preferencesProvider).markEmailLinked();

  Future<void> snoozeBanner() => ref
      .read(preferencesProvider)
      .snoozeEmailBannerUntil(DateTime.now().add(emailBannerSnoozeDuration));

  Future<void> dismissBanner() =>
      ref.read(preferencesProvider).dismissEmailBanner();
}

final emailLinkingProvider = NotifierProvider<EmailLinking, EmailLinkingState>(
  EmailLinking.new,
);

/// Alive while the e-mail issuance flow for linking is open, as opposed to the
/// flow that adds the e-mail credential. Only its presence is read.
final linkingFlowOpenProvider = Provider.autoDispose<bool>((ref) => true);
