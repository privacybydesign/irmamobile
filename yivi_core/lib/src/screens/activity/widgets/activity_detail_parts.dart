import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/glass/glass_group.dart";
import "../../../widgets/irma_avatar.dart";
import "activity_card.dart";

/// How an activity reads at the top of its detail view.
enum ActivityKind {
  shared(
    relationKey: "activity.shared_with",
    titleKey: "activity.shared_data",
    noteKey: "activity.note.shared",
    icon: Icons.arrow_upward_rounded,
    badge: Color(0xFF1D4E89),
  ),
  received(
    relationKey: "activity.received_from",
    titleKey: "activity.received_data",
    noteKey: "activity.note.received",
    icon: Icons.arrow_downward_rounded,
    badge: Color(0xFF00973A),
  ),
  deleted(
    relationKey: "activity.deleted_from",
    titleKey: "activity.deleted_data",
    noteKey: "activity.note.deleted",
    icon: Icons.delete_outline_rounded,
    badge: Color(0xFFBD1919),
  ),
  signed(
    relationKey: "activity.signed_for",
    titleKey: "activity.shared_data",
    noteKey: "activity.note.signed",
    icon: Icons.edit_rounded,
    badge: Color(0xFF484747),
  );

  final String relationKey;
  final String titleKey;
  final String noteKey;
  final IconData icon;

  /// The badge colour; white icons on it, in both themes.
  final Color badge;

  const ActivityKind({
    required this.relationKey,
    required this.titleKey,
    required this.noteKey,
    required this.icon,
    required this.badge,
  });

  static ActivityKind of(LogInfo logEntry) => switch (logEntry.type) {
    LogType.disclosure => shared,
    LogType.issuance => received,
    LogType.removal => deleted,
    LogType.signature => signed,
  };
}

/// The other party of an activity: its logo (or first letter) with a badge
/// for what happened, "Shared with" / "Received from" and its name, and
/// "Known party" when Yivi knows it.
class ActivityPartyCard extends StatelessWidget {
  final LogInfo logEntry;

  const ActivityPartyCard({super.key, required this.logEntry});

  bool? get _verified => switch (logEntry.type) {
    LogType.disclosure => logEntry.disclosureLog!.verifier?.verified,
    LogType.signature => logEntry.signedMessageLog!.verifier?.verified,
    LogType.issuance => logEntry.issuanceLog!.issuer?.verified,
    LogType.removal => null,
  };

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final summary = activitySummary(logEntry);
    final kind = ActivityKind.of(logEntry);
    final verified = _verified ?? false;

    return GlassGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 16,
            children: [
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 60,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IrmaAvatar(
                        size: 56,
                        initials: summary.title.isEmpty
                            ? null
                            : summary.title.characters.first,
                        logoImage: summary.logo == null
                            ? null
                            : Base64Image(
                                base64: summary.logo!.base64,
                                mimeType: summary.logo!.mimeType,
                              ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: kind.badge,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: palette.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(kind.icon, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FlutterI18n.translate(context, kind.relationKey),
                      style: palette
                          .body(14)
                          .copyWith(color: palette.secondaryText),
                    ),
                    Text(summary.title, style: palette.display(18)),
                    if (verified)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          spacing: 4,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 14,
                              color: palette.successText,
                            ),
                            Text(
                              FlutterI18n.translate(
                                context,
                                "missing_data.known_party",
                              ),
                              style: palette
                                  .body(12, weight: FontWeight.w700)
                                  .copyWith(color: palette.successText),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A section of the detail view: a heading, then [children] 12 pt apart.
class ActivitySection extends StatelessWidget {
  final String titleKey;
  final List<Widget> children;

  const ActivitySection({
    super.key,
    required this.titleKey,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
          child: Semantics(
            header: true,
            child: Text(
              FlutterI18n.translate(context, titleKey),
              style: palette.display(16),
            ),
          ),
        ),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          children[i],
        ],
      ],
    );
  }
}

/// A credential in a log entry: a thumbnail of its card, its name and
/// issuer, and below them the attributes the log has (only the shared ones
/// for a disclosure).
class ActivityCredentialTile extends ConsumerWidget {
  final LogCredential credential;

  /// Only the shared attributes are listed (a disclosure or signature).
  final bool disclosure;

  /// The card is shown washed out (deleted data).
  final bool faded;

  const ActivityCredentialTile({
    super.key,
    required this.credential,
    this.disclosure = false,
    this.faded = false,
  });

  /// The card picture: a wallet card of the same type (which has the issuer's
  /// colours), or one built from the log.
  schemaless.Credential _card(List<schemaless.Credential> wallet) =>
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final wallet =
        ref.watch(schemalessCredentialOrderControllerProvider).value ??
        const <schemaless.Credential>[];

    return GlassGroup(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: 16,
                children: [
                  CredentialCardArt(
                    credential: _card(wallet),
                    width: 88,
                    greyedOut: faded,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credential.name,
                          style: palette
                              .display(16)
                              .copyWith(color: palette.text),
                        ),
                        Text(
                          credential.issuer.name,
                          style: palette
                              .body(12)
                              .copyWith(color: palette.heading),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (credential.attributes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: YiviCredentialCardAttributeList(
                    credential.attributes,
                    credentialId: credential.credentialId,
                    disclosure: disclosure,
                    showDividers: true,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The signed message, quoted with an accent bar along its left edge.
class ActivitySignedMessage extends StatelessWidget {
  final String message;

  const ActivitySignedMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return GlassGroup(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E5B46),
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Text(
                    message,
                    style: palette.body(15).copyWith(height: 23 / 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The small grey line at the end of the detail view.
class ActivityFootnote extends StatelessWidget {
  final ActivityKind kind;

  const ActivityFootnote({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
      child: Text(
        FlutterI18n.translate(context, kind.noteKey),
        style: palette
            .body(13)
            .copyWith(height: 18 / 13, color: palette.secondaryText),
      ),
    );
  }
}
