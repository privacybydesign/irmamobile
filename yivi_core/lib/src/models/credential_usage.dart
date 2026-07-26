import "dart:convert";

/// How often a stored credential instance has been disclosed, and when it was
/// disclosed last. Used to pre-select the option a user reaches for most when a
/// session offers several instances of the same credential.
///
/// Usage is keyed by credential hash, the identity irmago itself uses for a
/// stored instance. Re-issuing a credential produces a new hash, so its count
/// starts over — deliberate, since linking the two would mean storing
/// attribute-derived data about the credential outside irmago's own storage.
class CredentialUsage {
  /// Number of completed sessions in which this instance was disclosed.
  final int count;

  /// When the last of those sessions completed.
  final DateTime lastUsed;

  const CredentialUsage({required this.count, required this.lastUsed});

  CredentialUsage usedAt(DateTime now) =>
      CredentialUsage(count: count + 1, lastUsed: now);

  /// Decodes the stored blob: `{"<hash>": [count, lastUsedEpochMs]}`.
  ///
  /// Unreadable input yields an empty map and unreadable entries are skipped:
  /// a usage counter is a convenience, not something to fail a disclosure over.
  static Map<String, CredentialUsage> decode(String raw) {
    if (raw.isEmpty) return const {};

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const {};
    }
    if (decoded is! Map<String, dynamic>) return const {};

    final usage = <String, CredentialUsage>{};
    for (final entry in decoded.entries) {
      final value = entry.value;
      if (value is! List || value.length != 2) continue;
      final count = value[0];
      final lastUsedEpochMs = value[1];
      if (count is! int || lastUsedEpochMs is! int || count <= 0) continue;
      usage[entry.key] = CredentialUsage(
        count: count,
        lastUsed: DateTime.fromMillisecondsSinceEpoch(lastUsedEpochMs),
      );
    }
    return usage;
  }

  static String encode(Map<String, CredentialUsage> usage) => jsonEncode({
    for (final entry in usage.entries)
      entry.key: [
        entry.value.count,
        entry.value.lastUsed.millisecondsSinceEpoch,
      ],
  });
}
