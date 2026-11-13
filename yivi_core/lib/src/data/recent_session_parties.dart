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

  /// Records the latest state of session [sessionId] with [party].
  void record(
    int sessionId,
    TrustedParty party, {
    required bool completed,
    DateTime? time,
  }) {
    if (party.name.trim().isEmpty) return;
    _sessions.remove(sessionId);
    _sessions[sessionId] = RecentSessionParty(
      party: party,
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
        if (seen.add(entry.party.id)) entry,
    ];
  }
}
