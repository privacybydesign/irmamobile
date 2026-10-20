import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/requestor_trust.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../models/session_preview.dart";
import "../../../providers/waiting_request_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/irma_confirmation_dialog.dart";
import "../../session/widgets/session_requestor_header.dart";

/// The request waiting behind the lock screen, above the PIN: who it is
/// from (as far as Yivi knows before the PIN), a badge for what kind it is,
/// what they want, and how far they are vouched for.
///
/// Large on the lock screen itself, [compact] as a row on the PIN page of
/// the scanner sheet.
class WaitingRequestCard extends StatelessWidget {
  final WaitingRequest request;
  final bool compact;

  const WaitingRequestCard({
    super.key,
    required this.request,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final parts = _Parts.of(context, request);
    final logo = _Logo(parts: parts, size: compact ? 44 : 52);
    final name = Text(
      parts.name,
      key: const Key("waiting_request_name"),
      textAlign: compact ? TextAlign.start : TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: palette
          .display(compact ? 17 : 19, weight: FontWeight.w700)
          .copyWith(height: compact ? 22 / 17 : 25 / 19, color: palette.text),
    );
    final what = parts.what == null
        ? null
        : Text(
            parts.what!,
            key: const Key("waiting_request_kind"),
            textAlign: compact ? TextAlign.start : TextAlign.center,
            style: palette
                .body(compact ? 14 : 15)
                .copyWith(
                  height: compact ? 20 / 14 : 22 / 15,
                  color: palette.heading,
                ),
          );
    final pill = parts.pill == null ? null : _Pill(pill: parts.pill!);

    // Read as one sentence: "Webshop Noord, is asking for data,
    // Registered with Yivi".
    return Semantics(
      container: true,
      label: [parts.name, ?parts.what, ?parts.pill?.label].join(", "),
      child: ExcludeSemantics(
        child: GlassSurface(
          key: const Key("waiting_request_card"),
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(compact ? 24 : 28)),
          ),
          padding: compact
              ? const EdgeInsets.fromLTRB(14, 10, 14, 10)
              : const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: compact
              ? Row(
                  spacing: 14,
                  children: [
                    logo,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          name,
                          ?what,
                          if (pill != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: pill,
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: logo),
                    const SizedBox(height: 8),
                    name,
                    if (what != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: what,
                      ),
                    if (pill != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(child: pill),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The badge on the logo: what kind of request it is.
enum _Badge { share, add, sign }

class _PillParts {
  final String label;
  final IconData icon;
  final Color fill;
  final Color ink;
  final Color iconColor;

  const _PillParts({
    required this.label,
    required this.icon,
    required this.fill,
    required this.ink,
    required this.iconColor,
  });
}

/// What the card says for a [WaitingRequest].
class _Parts {
  final String name;
  final String? what;
  final TrustedParty? party;
  final IconData? icon;
  final _Badge? badge;
  final _PillParts? pill;

  const _Parts({
    required this.name,
    required this.what,
    required this.party,
    required this.icon,
    required this.badge,
    required this.pill,
  });

  factory _Parts.of(BuildContext context, WaitingRequest request) {
    final palette = YiviPalette.of(context);
    String t(String key) => FlutterI18n.translate(context, key);
    final preview = request.preview;
    final badge = switch (preview.kind) {
      SessionPreviewKind.disclosure => _Badge.share,
      SessionPreviewKind.issuance => _Badge.add,
      SessionPreviewKind.signature => _Badge.sign,
      SessionPreviewKind.unknown => null,
    };
    final what = switch (preview.kind) {
      SessionPreviewKind.disclosure => t("waiting_request.kind.disclosure"),
      SessionPreviewKind.issuance => t("waiting_request.kind.issuance"),
      SessionPreviewKind.signature => t("waiting_request.kind.signature"),
      SessionPreviewKind.unknown => null,
    };

    // The link in a confirmation email: the address it adds.
    final email = preview.email;
    if (email != null) {
      return _Parts(
        name: email,
        what: t("waiting_request.kind.email"),
        party: null,
        icon: Icons.mail_outline_rounded,
        badge: _Badge.add,
        pill: null,
      );
    }

    final requestor = preview.requestor;
    _PillParts neutral(String label, IconData icon) => _PillParts(
      label: label,
      icon: icon,
      fill: palette.outline,
      ink: palette.heading,
      iconColor: palette.secondaryText,
    );
    switch (preview.knowledge) {
      case SessionPreviewKnowledge.registered ||
              SessionPreviewKnowledge.unregistered
          when requestor != null:
        final registered =
            preview.knowledge == SessionPreviewKnowledge.registered;
        final _PillParts? pill;
        if (request.inFlight || registered) {
          // As the share page says it: who vouches.
          final style = RequestorTrustStyle.of(context, requestor);
          final label = style.label;
          pill = label == null
              ? null
              : _PillParts(
                  label: label,
                  icon: style.trust.vouched
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  fill: style.pillFill,
                  ink: style.pillInk,
                  iconColor: style.badge ?? style.pillInk,
                );
        } else {
          // Not in the scheme: said plainly, before anything is asked.
          pill = neutral(
            t("waiting_request.pill.unknown"),
            Icons.help_outline_rounded,
          );
        }
        return _Parts(
          name: requestor.name,
          what: what,
          party: requestor,
          icon: null,
          badge: badge,
          pill: pill,
        );
      case SessionPreviewKnowledge.host when preview.host.isNotEmpty:
        return _Parts(
          name: preview.host,
          what: what,
          party: TrustedParty(
            id: preview.host,
            name: preview.host,
            url: null,
            parent: null,
            verified: false,
          ),
          icon: null,
          badge: badge,
          pill: neutral(
            t("waiting_request.pill.website"),
            Icons.language_rounded,
          ),
        );
      case _:
        return _Parts(
          name: t("waiting_request.unknown_title"),
          what: badge == null ? null : what,
          party: null,
          icon: Icons.qr_code_scanner_rounded,
          badge: badge,
          pill: null,
        );
    }
  }
}

class _Logo extends StatelessWidget {
  final _Parts parts;
  final double size;

  const _Logo({required this.parts, required this.size});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final party = parts.party;
    final badge = parts.badge;
    final logo = party != null
        ? SessionRequestorHeader.avatarOf(party, size: size)
        : Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: palette.tint,
              shape: BoxShape.circle,
            ),
            child: Icon(parts.icon, size: size * 0.48, color: palette.link),
          );
    if (badge == null) return ExcludeSemantics(child: logo);
    final badgeSize = size * 0.46;
    return ExcludeSemantics(
      child: SizedBox(
        width: size + badgeSize * 0.25,
        height: size + badgeSize * 0.25,
        child: Stack(
          children: [
            logo,
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                key: ValueKey(("waiting_request_badge", badge.name)),
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: switch (badge) {
                    _Badge.share => palette.link,
                    _Badge.add => palette.successText,
                    _Badge.sign => palette.heading,
                  },
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.surface, width: 2.5),
                ),
                child: Icon(
                  switch (badge) {
                    _Badge.share => Icons.arrow_upward_rounded,
                    _Badge.add => Icons.add_rounded,
                    _Badge.sign => Icons.edit_rounded,
                  },
                  size: badgeSize * 0.56,
                  color: palette.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final _PillParts pill;

  const _Pill({required this.pill});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      key: const Key("waiting_request_pill"),
      height: 26,
      padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
      decoration: ShapeDecoration(
        color: pill.fill,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(pill.icon, size: 16, color: pill.iconColor),
          Flexible(
            child: Text(
              pill.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: palette
                  .body(12.5, weight: FontWeight.w700)
                  .copyWith(color: pill.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// The heading over the PIN while [request] waits.
String waitingHeadKey(WaitingRequest request) {
  final preview = request.preview;
  if (preview.email != null) return "waiting_request.head_email";
  if (preview.knowledge == SessionPreviewKnowledge.none &&
      preview.kind == SessionPreviewKind.unknown) {
    return "waiting_request.head_unknown";
  }
  return "waiting_request.head";
}

/// The line under the heading: what comes after the PIN when the card
/// can't say who asks, or null when the card says it all.
String? waitingDetail(BuildContext context, WaitingRequest request) {
  final preview = request.preview;
  String t(String key) => FlutterI18n.translate(context, key);
  if (preview.email != null) return t("waiting_request.detail.email");
  if (request.inFlight) return t("waiting_request.detail.in_flight");
  return switch (preview.knowledge) {
    SessionPreviewKnowledge.host => t("waiting_request.detail.host"),
    SessionPreviewKnowledge.none => t("waiting_request.detail.unknown"),
    _ => null,
  };
}

/// "Stop this request?" before the waiting [request] is dropped; true when
/// the user stops it.
Future<bool> confirmStopWaitingRequest(
  BuildContext context,
  WaitingRequest? request,
) async {
  final preview = request?.preview;
  final email = preview?.email != null;
  final name =
      preview?.requestor?.name ??
      (preview?.host.isNotEmpty ?? false ? preview!.host : null);
  return await showDialog<bool>(
        context: context,
        builder: (_) => IrmaConfirmationDialog(
          titleTranslationKey: email
              ? "waiting_request.stop.title_email"
              : "waiting_request.stop.title",
          contentTranslationKey: email
              ? "waiting_request.stop.body_email"
              : name == null
              ? "waiting_request.stop.body_unknown"
              : "waiting_request.stop.body",
          contentTranslationParams: {"name": ?name},
          confirmTranslationKey: "waiting_request.stop.confirm",
          cancelTranslationKey: "waiting_request.stop.keep",
          destructive: true,
        ),
      ) ??
      false;
}
