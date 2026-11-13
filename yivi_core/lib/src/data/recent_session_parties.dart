import "../models/schemaless/schemaless_events.dart";

/// A party the user recently had a session with.
class RecentSessionParty {
  final TrustedParty party;
  final DateTime time;

  /// Whether the session ended in success. A session that failed, was
  /// cancelled or is still open is not in the activity log.
  final bool completed;

  const RecentSessionParty({
    required this.party,
    required this.time,
    required this.completed,
  });
}

/// Who the user's recent sessions were with, including sessions that never
/// finished and so never reached the activity log. "Need help?" uses it to
/// put the user through to an organisation they got stuck with halfway.
///
/// Kept in memory only, on purpose: it is gone when the app restarts, so it
/// adds no stored record of what the user did.
class RecentSessionParties {
  static const _maxSessions = 20;

  /// By session id, in insertion order: map literals keep it.
  final _sessions = <int, RecentSessionParty>{};

  /// Remembers the server session [sessionId] talks to, from the QR code or
  /// link that started it. An IRMA session learns who the requestor is only
  /// after pairing; when the user gives up at the pairing code, the server
  /// is all the app knows. It stands in until [record] gets the requestor.
  void start(int sessionId, String pointerUrl, {DateTime? time}) {
    final host = serverHost(pointerUrl);
    if (host == null) return;
    record(
      sessionId,
      TrustedParty(
        id: "",
        name: host,
        url: null,
        parent: null,
        verified: false,
      ),
      completed: false,
      time: time,
    );
  }

  /// Records the latest state of session [sessionId] with [party]. A state
  /// without a requestor keeps the party known so far.
  void record(
    int sessionId,
    TrustedParty party, {
    required bool completed,
    DateTime? time,
  }) {
    final known = party.name.trim().isNotEmpty
        ? party
        : _sessions[sessionId]?.party;
    if (known == null) return;
    _sessions.remove(sessionId);
    _sessions[sessionId] = RecentSessionParty(
      party: known,
      time: time ?? DateTime.now(),
      completed: completed,
    );
    while (_sessions.length > _maxSessions) {
      _sessions.remove(_sessions.keys.first);
    }
  }

  /// One entry per party, most recent first, each from that party's latest
  /// session.
  List<RecentSessionParty> get recent {
    final seen = <String>{};
    return [
      for (final entry in _sessions.values.toList().reversed)
        if (seen.add(_keyOf(entry.party))) entry,
    ];
  }

  /// A server that is not in the scheme has no id, only its hostname as
  /// name.
  static String _keyOf(TrustedParty party) =>
      party.id.isNotEmpty ? party.id : party.name;

  /// The server a session pointer leads to: the host of an IRMA session
  /// URL, or of the URL an OpenID4VC link points at.
  static String? serverHost(String pointerUrl) {
    final uri = Uri.tryParse(pointerUrl.trim());
    if (uri == null) return null;
    if (uri.scheme == "https" || uri.scheme == "http") {
      return uri.host.isEmpty ? null : uri.host.toLowerCase();
    }
    for (final key in const ["credential_offer_uri", "request_uri"]) {
      final nested = Uri.tryParse(uri.queryParameters[key] ?? "");
      if (nested != null &&
          (nested.scheme == "https" || nested.scheme == "http") &&
          nested.host.isNotEmpty) {
        return nested.host.toLowerCase();
      }
    }
    return null;
  }
}
