import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../routing.dart";
import "../models/session.dart";
import "../routing/navigation.dart";
import "contact_issuance_provider.dart";
import "email_linking_provider.dart";
import "irma_repository_provider.dart";
import "nested_issuance_host_provider.dart";

/// What became of a pointer handed to [SessionLauncher.handle].
sealed class PointerOutcome {}

/// A session started: in the sheet that waited for it ([inSheet]), or on a
/// session screen pushed on the router.
final class SessionStarted extends PointerOutcome {
  final int sessionId;
  final bool inSheet;

  SessionStarted(this.sessionId, {required this.inSheet});
}

/// The link from a verification e-mail went to e-mail linking. With
/// [openLinking] the linking screens are not open yet and the caller opens
/// them (that needs a context); otherwise the open code screen picks the
/// link up itself.
final class LinkForLinking extends PointerOutcome {
  final EmailCodePointer link;
  final bool openLinking;

  LinkForLinking(this.link, {required this.openLinking});
}

/// The link from a verification e-mail had nothing to go to: linking is not
/// offered, an address is linked already, or the user is adding the e-mail
/// card itself.
final class LinkIgnored extends PointerOutcome {}

/// Starts what a scanned or opened pointer points to.
class SessionLauncher {
  SessionLauncher(this._ref);

  final Ref _ref;

  /// Handles [pointer]: the link in a verification e-mail goes to e-mail
  /// linking, a session pointer starts its session. With [replace] the
  /// session screen replaces the current page.
  ///
  /// The pending pointer is always cleared: for a session by its
  /// `NewSessionEvent`, in the same delivery that marks the session in
  /// flight, so the lock screen never sees neither (ADR 0004); for a link
  /// here.
  PointerOutcome handle(Pointer pointer, {bool replace = false}) =>
      switch (pointer) {
        EmailCodePointer() => _emailLink(pointer),
        SessionPointer() => _startSession(pointer, replace: replace),
      };

  /// Hands the link in the verification e-mail to e-mail linking. If its
  /// screens are already open, the code screen picks the link up from the
  /// provider.
  PointerOutcome _emailLink(EmailCodePointer link) {
    // A link that stays queued is handled again after every unlock, and keeps
    // the biometric unlock disabled.
    _ref.read(pendingPointerQueueProvider).clear();

    final linkingOpen = _ref.exists(
      contactIssuanceProvider(ContactFlow.linkEmail),
    );
    // Nothing takes the link in the flow that adds the e-mail credential, and
    // the next linking flow must not pick up a stale one.
    if (!linkingOpen &&
        _ref.exists(contactIssuanceProvider(ContactFlow.email))) {
      return LinkIgnored();
    }

    // Linking not offered, or an address linked already: nothing to link.
    if (!linkingOpen && !_ref.read(emailLinkAvailableProvider)) {
      return LinkIgnored();
    }

    _ref.read(emailLinkingProvider.notifier).receiveLink(link);
    return LinkForLinking(link, openLinking: !linkingOpen);
  }

  /// Starts the session and pushes its screen at once, or hands it to the
  /// [NestedIssuanceHost] waiting for it. The screen mounts before Go has
  /// sent a state and shows its loading branch while Go contacts the
  /// relying party.
  SessionStarted _startSession(
    SessionPointer pointer, {
    required bool replace,
  }) {
    final sessions = _ref.read(sessionRepositoryProvider);
    // Any session active at this moment is "underlying": ours does not exist
    // on the Go side yet, so we don't need to exclude it.
    final hasUnderlying = sessions.hasActiveSessions();
    final sessionId = sessions.startSession(pointer);

    // The user is adding a card in a sheet (the Change sheet of a waiting
    // request, or Add data): the issuance shows there, so no session screen
    // is pushed.
    final host = hostForNewSession(
      _ref.read(nestedIssuanceHostProvider),
      hasUnderlying: hasUnderlying,
      isActive: sessions.isActiveSession,
    );
    if (host != null) {
      host.attach(sessionId);
      return SessionStarted(sessionId, inSheet: true);
    }

    final location = SessionRouteParams(
      sessionId: sessionId,
      hasUnderlyingSession: hasUnderlying,
    ).location;
    final router = _ref.read(routerProvider);
    if (replace) {
      router.pushReplacement(location);
    } else {
      router.push(location);
    }
    return SessionStarted(sessionId, inSheet: false);
  }
}

final sessionLauncherProvider = Provider<SessionLauncher>(SessionLauncher.new);
