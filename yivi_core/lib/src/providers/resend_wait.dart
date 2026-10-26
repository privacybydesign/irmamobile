import "package:flutter_riverpod/flutter_riverpod.dart";

/// The time now, for the wait before a code can be sent again; a test sets
/// its own.
final resendClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// When a code may be sent to an address again (an e-mail address, a phone
/// number): a minute after it was first sent there. A send in that minute
/// is ignored and does not start the minute again. Another address can be
/// sent to at once; the wait is per address, so switching back and forth
/// does not get around it.
class ResendWait {
  static const wait = Duration(seconds: 60);

  final DateTime Function() now;
  final _sentAt = <String, DateTime>{};

  ResendWait(this.now);

  /// When [address] can get a code again; null when it can now.
  DateTime? resendAt(String address) {
    final sent = _sentAt[address];
    if (sent == null) return null;
    final at = sent.add(wait);
    return at.isAfter(now()) ? at : null;
  }

  /// Marks a send to [address], unless it is still waiting: then false, and
  /// the code is not to be sent.
  bool trySend(String address) {
    if (resendAt(address) != null) return false;
    _sentAt[address] = now();
    return true;
  }

  /// A send that did not go out (no connection, the issuer said no) does
  /// not count: the user can try again at once.
  void failed(String address) => _sentAt.remove(address);
}
