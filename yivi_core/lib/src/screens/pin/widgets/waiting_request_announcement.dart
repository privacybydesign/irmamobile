import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart";
import "../../../models/session_preview.dart";
import "../../../providers/waiting_request_provider.dart";
import "../../../theme/yivi_edges.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/i18n.dart";
import "../../../widgets/corner_badge.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../session/widgets/session_requestor_header.dart";

/// The request waiting behind the lock screen, above the PIN, as one
/// sentence: who it is from and what they want, as far as Yivi knows that
/// before the PIN, under a round avatar with a badge for the kind of
/// request. When Yivi can't know who asks (OpenID4VP/VCI, a redirect), it
/// says only what kind of request waits. The line under it is the PIN
/// screen's instruction ([waitingLineKey]).
class WaitingRequestAnnouncement extends StatelessWidget {
  final WaitingRequest request;

  const WaitingRequestAnnouncement({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final parts = _Parts.of(context, request);
    return Column(
      key: const Key("waiting_request_announcement"),
      mainAxisSize: MainAxisSize.min,
      children: [
        _Avatar(parts: parts, size: 56),
        const SizedBox(height: 14),
        // What the screen reader lands on; the line under it follows.
        Semantics(
          header: true,
          container: true,
          child: Text(
            parts.sentence,
            key: const Key("waiting_request_sentence"),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: palette
                .display(21, weight: FontWeight.w700)
                .copyWith(height: 27 / 21, color: palette.text),
          ),
        ),
      ],
    );
  }
}

/// The badge on the avatar: what kind of request it is.
enum _Badge { share, add, sign }

/// What the announcement says for a [WaitingRequest].
class _Parts {
  final String sentence;

  /// Whose avatar: null for a generic disc with [icon].
  final TrustedParty? party;
  final IconData? icon;
  final _Badge? badge;

  const _Parts({
    required this.sentence,
    required this.party,
    required this.icon,
    required this.badge,
  });

  factory _Parts.of(BuildContext context, WaitingRequest request) {
    final preview = request.preview;
    final kind = switch (preview.kind) {
      SessionPreviewKind.disclosure => "disclosure",
      SessionPreviewKind.issuance => "issuance",
      SessionPreviewKind.signature => "signature",
      SessionPreviewKind.unknown => null,
    };
    final badge = switch (preview.kind) {
      SessionPreviewKind.disclosure => _Badge.share,
      SessionPreviewKind.issuance => _Badge.add,
      SessionPreviewKind.signature => _Badge.sign,
      SessionPreviewKind.unknown => null,
    };

    // The link in a confirmation email: what it adds.
    if (preview.email != null) {
      return _Parts(
        sentence: context.tr("waiting_request.sentence.email"),
        party: null,
        icon: Icons.mail_outline_rounded,
        badge: _Badge.add,
      );
    }

    final requestor = preview.requestor;
    final named =
        requestor != null &&
        (request.inFlight ||
            preview.knowledge == SessionPreviewKnowledge.registered ||
            preview.knowledge == SessionPreviewKnowledge.unregistered);
    if (named) {
      final params = {"name": requestor.name};
      return _Parts(
        sentence: request.inFlight
            ? context.tr("waiting_request.sentence.in_flight", params)
            : context.tr(
                "waiting_request.sentence.${kind ?? "disclosure"}",
                params,
              ),
        party: requestor,
        icon: null,
        badge: badge,
      );
    }

    // Who asks can't be known before the PIN (OpenID4VP/VCI only give a
    // host, which isn't who asks; a redirect gives nothing): only what kind
    // of request waits.
    return _Parts(
      sentence: context.tr("waiting_request.generic.${kind ?? "unknown"}"),
      party: null,
      icon: switch (badge) {
        _Badge.share => Icons.arrow_upward_rounded,
        _Badge.add => Icons.add_rounded,
        _Badge.sign => Icons.edit_rounded,
        null => Icons.question_mark_rounded,
      },
      badge: null,
    );
  }
}

class _Avatar extends StatelessWidget {
  final _Parts parts;
  final double size;

  const _Avatar({required this.parts, required this.size});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final party = parts.party;
    final badge = parts.badge;
    final avatar = party != null
        ? requestorAvatar(party, size: size)
        : Container(
            key: const Key("waiting_request_generic"),
            width: size,
            height: size,
            // White, as the keys: a tint disappears on the lock screen's
            // background.
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(YiviEdges.block(context)),
            ),
            child: Icon(parts.icon, size: size * 0.46, color: palette.link),
          );
    if (badge == null) return ExcludeSemantics(child: avatar);
    final badgeSize = size * 0.46;
    return ExcludeSemantics(
      child: SizedBox(
        width: size + badgeSize * 0.2,
        height: size + badgeSize * 0.2,
        child: Stack(
          children: [
            avatar,
            Positioned(
              right: 0,
              bottom: 0,
              child: CornerBadge(
                key: ValueKey(("waiting_request_badge", badge.name)),
                icon: switch (badge) {
                  _Badge.share => Icons.arrow_upward_rounded,
                  _Badge.add => Icons.add_rounded,
                  _Badge.sign => Icons.edit_rounded,
                },
                fill: switch (badge) {
                  _Badge.share => palette.link,
                  _Badge.add => palette.successText,
                  _Badge.sign => palette.heading,
                },
                size: badgeSize,
                iconSize: badgeSize * 0.56,
                ink: palette.surface,
                ring: palette.surface,
                ringWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The line under the announcement, the PIN screen's instruction: what the
/// PIN shows next.
String waitingLineKey(WaitingRequest request) {
  final preview = request.preview;
  if (request.inFlight) return "waiting_request.line.continue";
  if (preview.email != null) return "waiting_request.line.see";
  return switch (preview.knowledge) {
    SessionPreviewKnowledge.registered || SessionPreviewKnowledge.unregistered
        when preview.requestor != null =>
      "waiting_request.line.see",
    _ => "waiting_request.line.who",
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
  // A host (OpenID4VP/VCI) isn't who asks: no name then.
  final name =
      request?.inFlight == true ||
          preview?.knowledge == SessionPreviewKnowledge.registered ||
          preview?.knowledge == SessionPreviewKnowledge.unregistered
      ? preview?.requestor?.name
      : null;
  return showConfirmDialog(
    context,
    titleKey: email
        ? "waiting_request.stop.title_email"
        : "waiting_request.stop.title",
    messageKey: email
        ? "waiting_request.stop.body_email"
        : name == null
        ? "waiting_request.stop.body_unknown"
        : "waiting_request.stop.body",
    messageParams: {"name": ?name},
    confirmKey: "waiting_request.stop.confirm",
    cancelKey: "waiting_request.stop.keep",
    destructive: true,
  );
}
