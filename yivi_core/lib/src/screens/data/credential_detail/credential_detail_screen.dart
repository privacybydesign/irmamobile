import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/date_formatter.dart";
import "../../../util/i18n.dart";
import "../../../util/instance_hint.dart";
import "../../../widgets/app_toast.dart";
import "../../../widgets/centred_max_width.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "../../../widgets/credential_card/models/credential_card_status.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/status_chip.dart";
import "../../../widgets/surface_card.dart";
import "../../../widgets/two_pane.dart";
import "../../add_data/add_data_sheet.dart";
import "../wallet/card_hero.dart";
import "../wallet/wallet_detail_scaffold.dart";

/// One entry in a card's activity section.
class CardActivityItem {
  final String title;
  final DateTime date;

  const CardActivityItem({required this.title, required this.date});
}

/// The log entries that involve one card (by hash).
///
/// The history log cannot be filtered per credential yet, so this returns
/// nothing for now; the detail view already shows the section and its rows.
/// The widest the card and its details are: any wider, on a tablet or a
/// phone held sideways, and they would stretch.
const _maxWidth = 460.0;

final cardActivityProvider = Provider.family<List<CardActivityItem>, String>(
  (ref, hash) => const [],
);

/// Full-screen detail of one card (credential instance). Opens with the
/// Wallet-style transition: the card flies here as a [CardHero] while the data
/// tab pushes its other content away, then the details fade in from below.
class CredentialDetailScreen extends ConsumerStatefulWidget {
  final String hash;

  const CredentialDetailScreen({required this.hash});

  @override
  ConsumerState<CredentialDetailScreen> createState() =>
      _CredentialDetailScreenState();
}

class _CredentialDetailScreenState
    extends ConsumerState<CredentialDetailScreen> {
  late String _hash = widget.hash;

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final cards = ref.watch(walletCardsProvider);
    final credential = cards.firstWhereOrNull((c) => c.hash == _hash);

    final hints = ref.watch(instanceHintsProvider);
    final hintText = credential == null
        ? null
        : instanceHintText(context, hints[_hash] ?? const NoHint());

    return WalletDetailScaffold(
      openKey: _hash,
      closeKey: const Key("credential_detail_done"),
      builder: (context, physics, animation) {
        if (credential == null) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 32).clamp(0.0, _maxWidth);
            return ListView(
              // Pulling down at the top dismisses the page.
              physics: physics,
              padding: EdgeInsets.fromLTRB(
                16,
                padding.top + 76,
                16,
                padding.bottom + 32,
              ),
              children: [
                Center(
                  child: Semantics(
                    button: true,
                    label: FlutterI18n.translate(
                      context,
                      "wallet.detail.back_to_cards",
                    ),
                    child: GestureDetector(
                      onTap: _close,
                      child: CardHero(
                        credential: credential,
                        width: width,
                        hintText: hintText,
                      ),
                    ),
                  ),
                ),
                WalletReveal(
                  animation: animation,
                  child: CentredMaxWidth(
                    maxWidth: _maxWidth,
                    child: _Details(
                      credential: credential,
                      siblings: cards
                          .where(
                            (c) => c.credentialId == credential.credentialId,
                          )
                          .toList(),
                      hintTexts: {
                        for (final c in cards)
                          c.hash: instanceHintText(
                            context,
                            hints[c.hash] ?? const NoHint(),
                          ),
                      },
                      onSwitch: (hash) => setState(() => _hash = hash),
                      onDeleted: _close,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// The detail view of one card inside the detail pane of the tablet layout:
/// the same content as [CredentialDetailScreen], without the route
/// transition and the Done button.
class CredentialDetailPane extends ConsumerWidget {
  final String hash;

  /// Called with another card of the same type, picked in the siblings row.
  final ValueChanged<String> onSwitch;

  /// Called when the card was deleted.
  final VoidCallback onDeleted;

  const CredentialDetailPane({
    super.key,
    required this.hash,
    required this.onSwitch,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(walletCardsProvider);
    final credential = cards.firstWhereOrNull((c) => c.hash == hash);
    if (credential == null) return const SizedBox.shrink();

    final hints = ref.watch(instanceHintsProvider);
    final hintText = instanceHintText(context, hints[hash] ?? const NoHint());
    // Held sideways the pane is low: the card shows small, beside its name,
    // instead of big above the details.
    final compact = usePhoneLandscape(context);
    final details = _Details(
      credential: credential,
      showTitle: !compact,
      siblings: cards
          .where((c) => c.credentialId == credential.credentialId)
          .toList(),
      hintTexts: {
        for (final c in cards)
          c.hash: instanceHintText(context, hints[c.hash] ?? const NoHint()),
      },
      onSwitch: onSwitch,
      onDeleted: onDeleted,
    );
    final padding = paneContentPadding(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // The room inside the padding, which is wider at a side panel: a
        // card any wider would be squeezed to fit, out of proportion.
        final width = (constraints.maxWidth - padding.horizontal).clamp(
          0.0,
          _maxWidth,
        );
        return ListView(
          key: Key("credential_detail_pane_$hash"),
          padding: padding,
          children: [
            if (compact)
              _CompactHeader(credential: credential, hintText: hintText)
            else
              Center(
                child: CredentialCardArt(
                  credential: credential,
                  width: width,
                  hintText: hintText,
                ),
              ),
            CentredMaxWidth(maxWidth: _maxWidth, child: details),
          ],
        );
      },
    );
  }
}

/// The top of the detail pane on a phone held sideways: the card, 112
/// wide, with its name and issuer beside it.
class _CompactHeader extends StatelessWidget {
  final schemaless.Credential credential;
  final String hintText;

  const _CompactHeader({required this.credential, required this.hintText});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Row(
      key: const Key("credential_detail_compact_header"),
      spacing: 14,
      children: [
        CredentialCardArt(
          credential: credential,
          width: 112,
          hintText: hintText,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  credential.name,
                  style: palette.display(20, weight: FontWeight.w700),
                ),
              ),
              Text(
                credential.issuer.name,
                style: palette.body(14).copyWith(color: palette.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Details extends ConsumerWidget {
  final schemaless.Credential credential;
  final List<schemaless.Credential> siblings;
  final Map<String, String> hintTexts;
  final ValueChanged<String> onSwitch;
  final VoidCallback onDeleted;

  /// Whether the details start with the card's name and issuer (not when a
  /// compact header above them shows those).
  final bool showTitle;

  const _Details({
    required this.credential,
    this.showTitle = true,
    required this.siblings,
    required this.hintTexts,
    required this.onSwitch,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final lang = context.lang;
    final status = CredentialCardStatus(
      expiryDateUnix: credential.expiryDate,
      revoked: credential.revoked,
      batchInstanceCountsRemaining: credential.batchInstanceCountsRemaining,
      credentialId: credential.credentialId,
      issueUrl: credential.issueUrl,
    );
    final format = _formatLabel(credential);
    final source = _sourceLabel(context, credential);
    final activity = ref.watch(cardActivityProvider(credential.hash));
    final issued = credential.issuanceDate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(credential.issuanceDate! * 1000);
    final canReobtain = (credential.issueUrl ?? "").isNotEmpty;
    final canDelete = credential.credentialInstanceIds.isNotEmpty;
    final sharable =
        credential.credentialInstanceIds.keys.any(
          (f) => f != CredentialFormat.idemix,
        )
        ? status.instanceCount
        : null;

    Widget heading(String key, {Map<String, String>? params}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          FlutterI18n.translate(context, key, translationParams: params),
          style: palette.display(16),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    credential.name,
                    style: palette.display(24, weight: FontWeight.w700),
                  ),
                ),
                Text(
                  credential.issuer.name,
                  style: palette
                      .body(14)
                      .copyWith(color: palette.secondaryText),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _validityChip(context, status, lang),
            StatusChip(label: source),
          ],
        ),
        if (siblings.length > 1) ...[
          heading(
            "wallet.detail.siblings",
            params: {"count": "${siblings.length}"},
          ),
          SizedBox(
            height: 81 + 6 + 10 + 4 + 16,
            // Opens with the card shown in view (a card picked here opens a
            // new pane): in the middle when the row has to scroll.
            child: _SiblingScroll(
              index: siblings.indexWhere((s) => s.hash == credential.hash),
              count: siblings.length,
              builder: (controller) => ListView.separated(
                controller: controller,
                scrollDirection: Axis.horizontal,
                itemCount: siblings.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final s = siblings[i];
                  final selected = s.hash == credential.hash;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: "${s.name}, ${hintTexts[s.hash] ?? ""}",
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => onSwitch(s.hash),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: ShapeDecoration(
                              // Follows the card's corners, 5 points out (the
                              // gap and the ring).
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    CredentialCardArt.radiusFor(128) +
                                    const BorderRadius.all(Radius.circular(5)),
                                side: BorderSide(
                                  width: 2,
                                  color: selected
                                      ? palette.primary
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                            child: CredentialCardArt(
                              credential: s,
                              width: 128,
                              hintText: hintTexts[s.hash],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Under the card itself, not its ring (3 apart and
                          // 2 wide).
                          Container(
                            width: 136,
                            padding: const EdgeInsets.only(left: 5),
                            child: Text(
                              hintTexts[s.hash] ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: palette.body(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        heading("wallet.detail.details"),
        SurfaceCard(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: YiviCredentialCardAttributeList(
            credential.attributes,
            credentialId: credential.credentialId,
            showDividers: true,
          ),
        ),
        if (sharable != null) ...[
          heading("credential.sharable"),
          SurfaceCard(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  FlutterI18n.translate(
                    context,
                    "credential.sharable_count",
                    translationParams: {"count": "$sharable"},
                  ),
                  style: palette.body(14, weight: FontWeight.w600),
                ),
                Text(
                  FlutterI18n.translate(
                    context,
                    "wallet.detail.sharable_explanation",
                  ),
                  style: palette
                      .body(12)
                      .copyWith(color: palette.secondaryText),
                ),
              ],
            ),
          ),
        ],
        heading("wallet.detail.activity"),
        SurfaceCard(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final item in activity)
                _ActivityRow(
                  title: item.title,
                  date: printableDate(item.date, lang),
                ),
              if (issued != null)
                _ActivityRow(
                  title: FlutterI18n.translate(
                    context,
                    "wallet.detail.added_to_yivi",
                  ),
                  date: printableDate(issued, lang),
                  last: true,
                ),
              if (activity.isEmpty && issued == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    FlutterI18n.translate(
                      context,
                      "wallet.detail.activity_empty",
                    ),
                    style: palette
                        .body(13)
                        .copyWith(color: palette.secondaryText),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _AboutRow(
          label: FlutterI18n.translate(context, "wallet.detail.issued_by"),
          value: credential.issuer.name,
        ),
        _AboutRow(
          label: FlutterI18n.translate(context, "wallet.detail.format"),
          value: format,
        ),
        _AboutRow(
          label: FlutterI18n.translate(context, "wallet.detail.card_design"),
          value: source,
        ),
        if (issued != null)
          _AboutRow(
            label: FlutterI18n.translate(context, "wallet.detail.added"),
            value: printableDate(issued, lang),
          ),
        const SizedBox(height: 24),
        if (canReobtain)
          PillButton(
            key: const Key("credential_detail_reobtain"),
            style: PillStyle.neutral,
            label: FlutterI18n.translate(
              context,
              "credential.options.reobtain",
            ),
            onPressed: () => obtainAgain(
              context,
              ref,
              credentialId: credential.credentialId,
              issueUrl: credential.issueUrl,
              card: credential,
            ),
          ),
        if (canDelete)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: PillButton(
              key: const Key("credential_detail_delete"),
              style: PillStyle.danger,
              leading: Icon(
                Icons.delete_outline,
                color: palette.danger,
                size: 20,
              ),
              label: FlutterI18n.translate(
                context,
                "credential.options.delete",
              ),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ),
      ],
    );
  }

  Widget _validityChip(
    BuildContext context,
    CredentialCardStatus status,
    String lang,
  ) {
    final expiry = status.expiryDate?.dateTime;
    if (status.revoked) {
      return StatusChip(
        label: FlutterI18n.translate(context, "credential.revoked"),
        tone: DialogTone.danger,
        icon: Icons.block,
      );
    }
    if (status.isExpired && expiry != null) {
      return StatusChip(
        label: FlutterI18n.translate(
          context,
          "credential.expired_on",
          translationParams: {"date": printableDate(expiry, lang)},
        ),
        tone: DialogTone.danger,
        icon: Icons.warning_amber_rounded,
      );
    }
    if (status.hasWarning && expiry != null) {
      return StatusChip(
        label: FlutterI18n.translate(
          context,
          "credential.expires_on",
          translationParams: {"date": printableDate(expiry, lang)},
        ),
        tone: DialogTone.warning,
        icon: Icons.schedule,
      );
    }
    return StatusChip(
      label: expiry == null
          ? FlutterI18n.translate(context, "wallet.detail.valid_indefinitely")
          : FlutterI18n.translate(
              context,
              "wallet.detail.valid_until",
              translationParams: {"date": printableDate(expiry, lang)},
            ),
      tone: DialogTone.success,
      icon: Icons.check,
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDeleteCredential(context);
    if (!confirmed || !context.mounted) return;
    // Shown on the Data tab, once this page has closed.
    final toast = appToastFor(context, overTabBar: true);
    final message = FlutterI18n.translate(
      context,
      "credential.options.delete_success",
    );
    IrmaRepositoryProvider.of(
      context,
    ).deleteCredential(credential.credentialInstanceIds);
    onDeleted();
    toast(message);
  }
}

String _formatLabel(schemaless.Credential c) {
  final formats = c.credentialInstanceIds.keys.toSet();
  return [
    if (formats.contains(CredentialFormat.idemix)) "Yivi (idemix)",
    if (formats.contains(CredentialFormat.sdjwtvc)) "SD-JWT VC",
    if (formats.contains(CredentialFormat.msoMdoc)) "mdoc",
  ].join(", ");
}

String _sourceLabel(BuildContext context, schemaless.Credential c) {
  final display = c.display;
  final key = (display?.svgTemplates.isNotEmpty ?? false)
      ? "credential_card.source.issuer_design"
      : (display?.backgroundColor != null || display?.backgroundImage != null)
      ? "credential_card.source.issuer_colours"
      : "credential_card.source.yivi";
  return FlutterI18n.translate(context, key);
}

class _ActivityRow extends StatelessWidget {
  final String title;
  final String date;
  final bool last;

  const _ActivityRow({
    required this.title,
    required this.date,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Row(
        spacing: 16,
        children: [
          const ToneDisc(icon: Icons.history, tone: DialogTone.info, size: 40),
          // The date under what happened, as in the design.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: palette
                      .body(14, weight: FontWeight.w600)
                      .copyWith(height: 20 / 14),
                ),
                Text(
                  date,
                  style: palette
                      .body(12)
                      .copyWith(color: palette.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Expanded(
            child: Text(
              label,
              style: palette.body(14).copyWith(color: palette.secondaryText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: palette.body(14).copyWith(color: palette.heading),
            ),
          ),
        ],
      ),
    );
  }
}

/// The horizontal row of the cards of a type, opening with the one at
/// [index] in view: scrolled so it is in the middle when the row is wider
/// than its room.
class _SiblingScroll extends StatefulWidget {
  final int index;
  final int count;
  final Widget Function(ScrollController controller) builder;

  const _SiblingScroll({
    required this.index,
    required this.count,
    required this.builder,
  });

  /// One card in the row: 128, its ring (3 apart, 2 wide) on both sides.
  static const double _item = 128 + 10;
  static const double _gap = 8;

  @override
  State<_SiblingScroll> createState() => _SiblingScrollState();
}

class _SiblingScrollState extends State<_SiblingScroll> {
  ScrollController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _controller ??= ScrollController(
        initialScrollOffset: _offset(constraints.maxWidth),
      );
      return widget.builder(_controller!);
    },
  );

  double _offset(double width) {
    const item = _SiblingScroll._item, gap = _SiblingScroll._gap;
    final total = widget.count * item + (widget.count - 1) * gap;
    final i = widget.index;
    if (i < 0 || total <= width) return 0;
    final start = i * (item + gap);
    // Already in view from the start: leave the row where it begins.
    if (start + item <= width) return 0;
    return (start + item / 2 - width / 2).clamp(0.0, total - width);
  }
}
