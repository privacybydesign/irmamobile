import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/credential.dart";
import "../../providers/credentials_provider.dart";
import "../../providers/email_linking_provider.dart";
import "../../providers/session_state_provider.dart";
import "../../providers/session_user_choices_provider.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/i18n.dart";
import "../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../widgets/sheet/sheet.dart";
import "../../widgets/sheet/sheet_actions.dart";
import "../../widgets/surfaces/inset_group.dart";
import "../../widgets/text/caps_label.dart";
import "../session/issue_flow/issue_sheet.dart";
import "email_linking.dart";

/// Whether [credentialId] is an e-mail card (of any scheme: pbdf, staging,
/// the demo scheme).
bool isEmailCard(String credentialId) =>
    credentialId.endsWith(".sidn-pbdf.email");

/// The e-mail cards in the app, oldest first.
final emailCardsProvider = Provider<List<Credential>>((ref) {
  final cards = ref.watch(credentialsProvider).value?.credentials ?? const [];
  return [
    for (final c in cards)
      if (isEmailCard(c.credentialId)) c,
  ];
});

/// Setting up is unfinished: the app has data, and no e-mail address is
/// linked to block it with (while linking is offered at all). More shows
/// "Finish setting up Yivi" and a dot until it is.
final setupUnfinishedProvider = Provider<bool>(
  (ref) =>
      ref.watch(emailLinkAvailableProvider) &&
      ref.watch(hasCredentialsProvider),
);

/// Which "Success" leads on to securing the app ([secureOfferFor]).
enum SecureOfferKind {
  /// The first card added in the app: "Now secure your app" (B).
  firstCard,

  /// An e-mail card: "Secure your app with it?" (C).
  emailCard,
}

/// Which offer "Success" in Add data makes for the added [cards], if any:
/// only while linking is [available] (offered, nothing linked), not while
/// [linking] already, and for one card. An e-mail card always gets its own
/// offer; another card only when the app had no data before ([hadCards])
/// and the first-card offer was not [shownBefore].
SecureOfferKind? secureOfferFor({
  required List<Credential> cards,
  required bool linking,
  required bool available,
  required bool hadCards,
  required bool shownBefore,
}) {
  if (linking || cards.length != 1 || !available) return null;
  if (isEmailCard(cards.single.credentialId)) return SecureOfferKind.emailCard;
  if (hadCards || shownBefore) return null;
  return SecureOfferKind.firstCard;
}

/// The address on e-mail card [card].
String emailAddressOf(Credential card) {
  for (final a in card.attributes) {
    if (a.claimPath.isNotEmpty && a.claimPath.last == "email") {
      return a.value?.string ?? "";
    }
  }
  return "";
}

/// Secures the app: links an e-mail address to it in MyYivi, so the app can
/// be blocked if the phone is lost. With e-mail cards in the app already,
/// one of those (no new code: the address is checked); else the e-mail
/// card's own flow, from the address.
Future<void> secureApp(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  // Loaded already: the Data tab under every way here watches them.
  final emails = container.read(emailCardsProvider);
  if (emails.isEmpty) return openEmailLinking(context);
  await showSheet<void>(
    context: context,
    builder: (context) => SecureAppSheet(emails: emails),
  );
}

/// Shares e-mail card [card] with the keyshare server, which links the
/// address to the app: the disclosure, with that card picked.
Future<void> linkEmailCard(BuildContext context, Credential card) =>
    shareEmailWithKeyshare(context, prefer: card.hash);

/// Picks the card with [hash] in session [sessionId] as soon as the
/// session says what it asks, so the share screen opens on it.
void preferCardInSession(
  ProviderContainer container,
  int sessionId,
  String hash,
) {
  late final ProviderSubscription<Object?> sub;
  var done = false;
  void pick() {
    if (done) return;
    final session = container.read(sessionStateProvider(sessionId)).value;
    // A session that ends without asking needs nothing picked.
    if (session != null && session.status.isTerminal) {
      done = true;
      scheduleMicrotask(sub.close);
      return;
    }
    if (session?.disclosurePlan case final plan?) {
      done = container
          .read(disclosureSelectionProvider(sessionId).notifier)
          .preferCard(plan, hash);
    }
    if (done) scheduleMicrotask(sub.close);
  }

  sub = container.listen(
    sessionStateProvider(sessionId),
    (_, _) => pick(),
    fireImmediately: true,
  );
}

/// "Secure your app" with the e-mail cards in the app: the one to use
/// (the first picked), or another address.
class SecureAppSheet extends StatefulWidget {
  final List<Credential> emails;

  const SecureAppSheet({super.key, required this.emails});

  @override
  State<SecureAppSheet> createState() => _SecureAppSheetState();
}

class _SecureAppSheetState extends State<SecureAppSheet> {
  late var _chosen = widget.emails.first;

  BuildContext get _root => Navigator.of(context, rootNavigator: true).context;

  void _use() {
    final root = _root;
    final card = _chosen;
    Navigator.of(context).pop();
    linkEmailCard(root, card);
  }

  void _another() {
    final root = _root;
    Navigator.of(context).pop();
    openEmailLinking(root);
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final many = widget.emails.length > 1;
    return SheetPage.scroll(
      key: const Key("secure_app_sheet"),
      title: SheetTitle(context.tr("secure.sheet.title")),
      padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
      action: SheetAction(
        key: const Key("secure_app_use"),
        label: context.tr("secure.sheet.use"),
        onTap: _use,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: YiviSpace.x8),
          Semantics(
            header: true,
            child: Text(
              context.tr(many ? "secure.sheet.many" : "secure.sheet.one"),
              style: palette.titleStep.copyWith(color: palette.text),
            ),
          ),
          const SizedBox(height: YiviSpace.x8),
          Text(
            context.tr("secure.sheet.text"),
            style: palette.body(16).copyWith(height: 24 / 16),
          ),
          const SizedBox(height: YiviSpace.x24),
          CapsLabel(
            context.tr("secure.sheet.in_app"),
            padding: const EdgeInsets.fromLTRB(4, 0, 4, YiviSpace.x8),
          ),
          for (final card in widget.emails) ...[
            _EmailTile(
              card: card,
              selected: card.hash == _chosen.hash,
              onTap: () => setState(() => _chosen = card),
            ),
            const SizedBox(height: YiviSpace.x12),
          ],
          InsetGroup(
            children: [
              ListTile(
                key: const Key("secure_app_another"),
                onTap: _another,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: YiviSpace.x16,
                  vertical: 2,
                ),
                leading: _DashedAdd(color: palette.link),
                title: Text(
                  context.tr("secure.sheet.another"),
                  style: palette
                      .body(16, weight: FontWeight.w600)
                      .copyWith(color: palette.link),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: palette.faint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// An e-mail card to pick: its card, the address, and a round check. The
/// picked one has the Change sheet's outline.
class _EmailTile extends StatelessWidget {
  final Credential card;
  final bool selected;
  final VoidCallback onTap;

  const _EmailTile({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final address = emailAddressOf(card);
    const shape = RoundedRectangleBorder(borderRadius: YiviCorners.cardRadius);
    return Semantics(
      selected: selected,
      button: true,
      label: address,
      excludeSemantics: true,
      child: DecoratedBox(
        // The outline sits outside the tile, 3 pt off it.
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(YiviCorners.card + 3),
            side: BorderSide(
              color: selected ? palette.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
            color: palette.surface,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: Key("secure_app_card_${card.hash}"),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: YiviSpace.x12,
                  vertical: YiviSpace.x12,
                ),
                child: Row(
                  spacing: YiviSpace.x12,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: CredentialCardArt(credential: card, width: 56),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: palette.body(16, weight: FontWeight.w600),
                          ),
                          Text(
                            "${card.name} · ${card.issuer.name}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: palette.rowSubtitle.copyWith(
                              color: palette.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Check(selected: selected),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final bool selected;

  const _Check({required this.selected});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? palette.primary : palette.surface,
        border: selected ? null : Border.all(color: palette.outline, width: 2),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

/// A card-sized dashed outline with a +: "another one".
class _DashedAdd extends StatelessWidget {
  final Color color;

  const _DashedAdd({required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 56,
    height: 36,
    child: CustomPaint(
      painter: _DashedRect(YiviPalette.of(context).faint),
      child: Center(child: Icon(Icons.add_rounded, size: 20, color: color)),
    ),
  );
}

class _DashedRect extends CustomPainter {
  final Color color;

  _DashedRect(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(5)),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRect old) => old.color != color;
}

/// The offer for the first card added in the app (B): the app has data now.
IssueSuccessOffer firstCardOffer(
  BuildContext context, {
  required VoidCallback onSecure,
  required VoidCallback onNotNow,
}) => (
  title: context.tr("secure.offer.title"),
  text: context.tr("secure.offer.text"),
  reasons: [
    (Icons.phonelink_lock_rounded, context.tr("secure.reason.block")),
    (Icons.history_rounded, context.tr("secure.reason.activity")),
    (Icons.mail_outline_rounded, context.tr("secure.reason.minute")),
  ],
  action: SheetAction(
    key: const Key("secure_offer_secure"),
    label: context.tr("secure.offer.secure"),
    onTap: onSecure,
  ),
  later: SheetAction(
    key: const Key("secure_offer_not_now"),
    label: context.tr("secure.offer.not_now"),
    onTap: onNotNow,
  ),
);

/// The offer for an e-mail card just added (C): use this address.
IssueSuccessOffer emailCardOffer(
  BuildContext context,
  Credential card, {
  required VoidCallback onSecure,
  required VoidCallback onNotNow,
}) => (
  title: context.tr("secure.offer.with_title"),
  text: context.tr("secure.offer.with_text", {"email": emailAddressOf(card)}),
  reasons: [
    (Icons.phonelink_lock_rounded, context.tr("secure.reason.block")),
    (Icons.history_rounded, context.tr("secure.reason.activity")),
    (Icons.verified_outlined, context.tr("secure.reason.no_code")),
  ],
  action: SheetAction(
    key: const Key("secure_offer_secure"),
    label: context.tr("secure.offer.secure"),
    onTap: onSecure,
  ),
  later: SheetAction(
    key: const Key("secure_offer_not_now"),
    label: context.tr("secure.offer.not_now"),
    onTap: onNotNow,
  ),
);
