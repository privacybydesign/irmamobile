import "package:collection/collection.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../util/string.dart";

/// What happened in a log entry.
enum ActivityKind {
  shared(
    labelKey: "activity.kind.shared",
    subtitleKey: "activity.data_shared",
    semanticsKey: "activity.data_shared_semantics",
    relationKey: "activity.shared_with",
    noteKey: "activity.note.shared",
    icon: Icons.arrow_upward_rounded,
    badge: Color(0xFF1D4E89),
  ),
  received(
    labelKey: "activity.kind.received",
    subtitleKey: "activity.data_received",
    semanticsKey: "activity.data_received_semantics",
    relationKey: "activity.received_from",
    noteKey: "activity.note.received",
    icon: Icons.arrow_downward_rounded,
    badge: Color(0xFF00973A),
  ),
  signed(
    labelKey: "activity.kind.signed",
    subtitleKey: "activity.message_signed",
    semanticsKey: "activity.signed_message_semantics",
    relationKey: "activity.signed_for",
    noteKey: "activity.note.signed",
    icon: Icons.edit_rounded,
    badge: Color(0xFF484747),
  ),
  deleted(
    labelKey: "activity.kind.deleted",
    subtitleKey: "activity.data_deleted",
    semanticsKey: "activity.data_deleted_semantics",
    relationKey: "activity.deleted_from",
    noteKey: "activity.note.deleted",
    icon: Icons.delete_outline_rounded,
    badge: Color(0xFFBD1919),
  );

  /// The short label: on the tags and the detail header ("Shared").
  final String labelKey;
  final String subtitleKey;
  final String semanticsKey;

  /// "Shared with", above the other party's name.
  final String relationKey;
  final String noteKey;
  final IconData icon;

  /// The badge colour; white icons on it, in both themes.
  final Color badge;

  const ActivityKind({
    required this.labelKey,
    required this.subtitleKey,
    required this.semanticsKey,
    required this.relationKey,
    required this.noteKey,
    required this.icon,
    required this.badge,
  });

  static ActivityKind of(LogType type) => switch (type) {
    LogType.disclosure => shared,
    LogType.issuance => received,
    LogType.removal => deleted,
    LogType.signature => signed,
  };
}

/// Why a card is in a log entry; each role is one section of the details.
enum ActivityRole {
  received("activity.section.received"),
  shared("activity.section.shared"),

  /// Shared with an issuer before it issued.
  sharedToReceive("activity.section.shared_to_receive"),
  signedWith("activity.section.signed_with"),
  deleted("activity.section.deleted");

  final String titleKey;

  const ActivityRole(this.titleKey);
}

/// The other party of a log entry.
class ActivityParty {
  final String name;
  final schemaless.LogoImage? logo;
  final bool verified;

  /// The host of the party's website, when the log has one.
  final String? host;

  const ActivityParty({
    required this.name,
    this.logo,
    this.verified = false,
    this.host,
  });

  factory ActivityParty.of(schemaless.TrustedParty party) => ActivityParty(
    name: party.name.replaceBreakingHyphens(),
    logo: party.image,
    verified: party.verified,
    host: _host(party.url),
  );

  static String? _host(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url.contains("://") ? url : "https://$url");
    final host = uri?.host ?? "";
    if (host.isEmpty) return null;
    return host.startsWith("www.") ? host.substring(4) : host;
  }
}

/// One card in a log entry, with what to draw it as.
class ActivityEntryCard {
  final LogCredential credential;
  final ActivityRole role;

  /// The card art: a wallet card of the same type (which has the issuer's
  /// colours), or one built from the log.
  final schemaless.Credential art;

  const ActivityEntryCard({
    required this.credential,
    required this.role,
    required this.art,
  });

  bool get deleted => role == ActivityRole.deleted;

  /// Only the shared values are in the log (a disclosure or signature).
  bool get disclosure => role != ActivityRole.received && !deleted;
}

class ActivityEntrySection {
  final ActivityRole role;
  final List<ActivityEntryCard> cards;

  const ActivityEntrySection(this.role, this.cards);
}

/// A log entry as the activity tab shows it: who, what happened, when, and
/// its cards in sections.
class ActivityEntry {
  final LogInfo log;
  final ActivityKind kind;
  final ActivityParty party;
  final List<ActivityEntrySection> sections;
  final String? message;

  const ActivityEntry._({
    required this.log,
    required this.kind,
    required this.party,
    required this.sections,
    this.message,
  });

  DateTime get localTime => log.time.toLocal();

  /// All cards, in the order of the sections: the order of the stack in a
  /// row and of the tiles in the details.
  List<ActivityEntryCard> get cards => [for (final s in sections) ...s.cards];

  /// Identifies the entry across reloads of the log (a [LogInfo] has no id).
  String get key => "${log.type.name}-${log.time.microsecondsSinceEpoch}";

  factory ActivityEntry.fromLog(
    LogInfo log, {
    List<schemaless.Credential> wallet = const [],
  }) {
    ActivityEntryCard card(LogCredential c, ActivityRole role) =>
        ActivityEntryCard(credential: c, role: role, art: _art(c, wallet));
    List<ActivityEntrySection> sections(
      List<(ActivityRole, List<LogCredential>)> parts,
    ) => [
      for (final (role, credentials) in parts)
        if (credentials.isNotEmpty)
          ActivityEntrySection(role, [
            for (final c in credentials) card(c, role),
          ]),
    ];

    final kind = ActivityKind.of(log.type);
    switch (log.type) {
      case LogType.issuance:
        final issuance = log.issuanceLog!;
        return ActivityEntry._(
          log: log,
          kind: kind,
          party: _partyOr(issuance.issuer, issuance.credentials),
          sections: sections([
            (ActivityRole.received, issuance.credentials),
            (ActivityRole.sharedToReceive, issuance.disclosedCredentials),
          ]),
        );
      case LogType.disclosure:
        final disclosure = log.disclosureLog!;
        return ActivityEntry._(
          log: log,
          kind: kind,
          party: _partyOr(disclosure.verifier, disclosure.credentials),
          sections: sections([(ActivityRole.shared, disclosure.credentials)]),
        );
      case LogType.signature:
        final signature = log.signedMessageLog!;
        return ActivityEntry._(
          log: log,
          kind: kind,
          party: _partyOr(signature.verifier, signature.credentials),
          sections: sections([
            (ActivityRole.signedWith, signature.credentials),
          ]),
          message: signature.message,
        );
      case LogType.removal:
        final removed = log.removalLog?.credentials ?? const <LogCredential>[];
        // No party in a removal: the issuer of the deleted data, with the
        // card's logo, never marked as verified.
        final first = removed.firstOrNull;
        return ActivityEntry._(
          log: log,
          kind: kind,
          party: ActivityParty(
            name: (first?.issuer.name ?? "").replaceBreakingHyphens(),
            logo: first?.image,
          ),
          sections: sections([(ActivityRole.deleted, removed)]),
        );
    }
  }

  /// The party, or else the issuer of the first card (an issuance whose
  /// issuer is not in the log).
  static ActivityParty _partyOr(
    schemaless.TrustedParty? party,
    List<LogCredential> credentials,
  ) {
    if (party != null && party.name.isNotEmpty) {
      return ActivityParty.of(party);
    }
    final first = credentials.firstOrNull;
    return ActivityParty(
      name: (first?.issuer.name ?? "").replaceBreakingHyphens(),
      logo: party?.image ?? first?.issuer.image,
    );
  }

  static schemaless.Credential _art(
    LogCredential credential,
    List<schemaless.Credential> wallet,
  ) =>
      wallet.firstWhereOrNull(
        (c) => c.credentialId == credential.credentialId,
      ) ??
      schemaless.Credential(
        credentialId: credential.credentialId,
        hash: credential.credentialId,
        name: credential.name,
        issuer: credential.issuer,
        image: credential.image,
        credentialInstanceIds: const {},
        batchInstanceCountsRemaining: const {},
        attributes: credential.attributes,
        revoked: credential.revoked,
        revocationSupported: credential.revocationSupported,
        issueUrl: credential.issueUrl,
        issuanceDate: credential.issuanceDate,
        expiryDate: credential.expiryDate,
      );
}
