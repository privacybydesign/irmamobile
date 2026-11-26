import "package:flutter/foundation.dart";

import "../../../models/return_url.dart";
import "../../../models/session.dart";
import "../../../models/session_state.dart";
import "../../../util/string.dart";

/// The platform a session runs on: how the app hands the user back to the
/// app that started it differs.
enum SessionPlatform { ios, android }

/// What decides what happens once a session is over.
@immutable
final class SessionFacts {
  const SessionFacts({
    required this.type,
    required this.returnUrl,
    required this.platform,
    required this.secondDevice,
    required this.inAppLaunched,
    required this.forRequest,
    required this.keyshareLink,
    this.nextPending = false,
  });

  final SessionType type;
  final ReturnURL? returnUrl;
  final SessionPlatform platform;

  /// The session was started from another device (by its QR code).
  final bool secondDevice;

  /// The issuance was launched from inside the app (Add data, OpenID4VCI).
  final bool inAppLaunched;

  /// An issuance during a request, which the user goes back to.
  final bool forRequest;

  /// The disclosure that links an e-mail address to the keyshare account.
  final bool keyshareLink;

  /// The requestor has a follow-up request waiting (IRMA `nextSession`).
  final bool nextPending;

  bool get _issuance => type == SessionType.issuance;
}

/// What the success screen is, and what runs once when it appears.
sealed class SessionOutcome {
  const SessionOutcome();
}

/// The e-mail address is linked; it is recorded as linked.
final class EmailLinked extends SessionOutcome {
  const EmailLinked();
}

/// Added during a request: "Back to {requestor}".
final class AddedForRequest extends SessionOutcome {
  const AddedForRequest();
}

/// Added: the card flies home on OK.
final class Added extends SessionOutcome {
  const Added();
}

/// The return URL is a phone number: call it via Yivi.
final class CallVia extends SessionOutcome {
  const CallVia(this.url);
  final ReturnURL url;
}

/// The return URL is an e-mail address: mail it via Yivi.
final class MailVia extends SessionOutcome {
  const MailVia(this.url);
  final ReturnURL url;
}

/// Shared (or signed), and the requestor has a follow-up request: "Verder"
/// starts it; no return URL is followed (2.14).
final class SharedMoreToCome extends SessionOutcome {
  const SharedMoreToCome();
}

/// "Shared with {requestor}", with what to do [next].
final class Shared extends SessionOutcome {
  const Shared(this.next);
  final SharedNext next;
}

/// An issuance with a return URL: a spinner while it is opened.
final class OpenReturnUrl extends SessionOutcome {
  const OpenReturnUrl(this.url);
  final ReturnURL url;
}

/// An issuance on iOS without a return URL: point at the status bar's back
/// link.
final class IssuedArrowBack extends SessionOutcome {
  const IssuedArrowBack();
}

/// An issuance on Android without a return URL: the app goes to the
/// background at once, so the app that started it shows.
final class IssuedToBackground extends SessionOutcome {
  const IssuedToBackground();
}

/// What the done screen of a shared session offers.
sealed class SharedNext {
  const SharedNext();
}

/// The result is on the other device.
final class OtherDevice extends SharedNext {
  const OtherDevice();
}

/// "Back to {host}": opens [url].
final class ReturnTo extends SharedNext {
  const ReturnTo(this.host, this.url);
  final String host;
  final ReturnURL url;
}

/// iOS: tap ◀ at the top left yourself.
final class GoBackYourself extends SharedNext {
  const GoBackYourself();
}

/// Android: "Back to the website" sends the app to the background.
final class BackToWebsite extends SharedNext {
  const BackToWebsite();
}

/// What happens after a session went through, given [f].
SessionOutcome sessionOutcomeOf(SessionFacts f) {
  final url = f.returnUrl;
  final ios = f.platform == SessionPlatform.ios;
  return switch (f) {
    // E-mail linking ends on its own screen once MijnYivi has the address.
    SessionFacts(keyshareLink: true) => const EmailLinked(),
    // A follow-up request wins over every way back.
    SessionFacts(nextPending: true, _issuance: false) =>
      const SharedMoreToCome(),
    SessionFacts(forRequest: true, _issuance: true) => const AddedForRequest(),
    // Started from inside the app: stay in the app, whatever return URL
    // the issuer set.
    SessionFacts(inAppLaunched: true) => const Added(),
    // The phone places the call, whichever device started the session.
    _ when url != null && url.isPhoneNumber => CallVia(url),
    _ when url != null && url.isEmail => MailVia(url),
    // The result lives on the other device, whose browser honours any
    // return URL there; nothing opens on the phone.
    SessionFacts(secondDevice: true, _issuance: true) => const Added(),
    SessionFacts(secondDevice: true) => const Shared(OtherDevice()),
    // Same device: back to where the user started.
    _ when url != null =>
      f._issuance
          ? OpenReturnUrl(url)
          : Shared(ReturnTo(url.uri.host.withoutWww(), url)),
    // No return URL: iOS has no way back but its status bar link; Android
    // moves the app to the background.
    SessionFacts(_issuance: false) => Shared(
      ios ? const GoBackYourself() : const BackToWebsite(),
    ),
    _ => ios ? const IssuedArrowBack() : const IssuedToBackground(),
  };
}

/// How closing an error (or the call screen's Cancel) hands back to the caller.
enum CallerReturn {
  /// iOS: point at the status bar's back link, and stay.
  arrowBack,

  /// Android: send the app to the background.
  background,

  /// Just leave the session.
  none,
}

/// Closing a session that did not go through (or the call screen's Cancel):
/// the return URL to [reopen] silently, then how to hand back to the
/// [caller]. [error]: the error shown, if any.
({ReturnURL? reopen, CallerReturn caller}) sessionCloseOf(
  SessionFacts f, {
  required SessionError? error,
}) {
  final url = f.returnUrl;
  final reopen =
      url != null &&
      !url.isPhoneNumber &&
      !url.isEmail &&
      // On a second device the browser is on the other device.
      !f.secondDevice &&
      error?.errorType != "clientReturnUrl" &&
      // Started from inside the app: the user expects to stay in it.
      !f.inAppLaunched;
  // Without a return URL the caller is the app that handed the session
  // over, typically the browser the user started in; a retry lives there.
  final toCaller =
      url == null && !f.inAppLaunched && !f.forRequest && !f.secondDevice;
  return (
    reopen: reopen ? url : null,
    caller: !toCaller
        ? CallerReturn.none
        : f.platform == SessionPlatform.ios
        ? CallerReturn.arrowBack
        : CallerReturn.background,
  );
}
