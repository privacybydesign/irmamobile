import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/credential_events.dart";
import "../../../models/log_entry.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/date_formatter.dart";
import "../../../util/instance_hint.dart";
import "../../../widgets/app_toast.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "../../../widgets/credential_card/models/credential_card_status.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../wallet/card_hero.dart";
import "../wallet/wallet_transition.dart";

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
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (animation != _routeAnimation) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _routeAnimation = animation?..addStatusListener(_onRouteStatus);
    }
    // Opened without a tap on a card (e.g. from a notification): still let
    // the data tab know which card is open.
    WalletTransition.openHash.value ??= _hash;
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      WalletTransition.openHash.value = null;
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (WalletTransition.openHash.value == _hash) {
        WalletTransition.openHash.value = null;
      }
    });
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  void _switchTo(String hash) {
    setState(() => _hash = hash);
    WalletTransition.openHash.value = hash;
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final cards =
        ref.watch(schemalessCredentialOrderControllerProvider).value ??
        const <schemaless.Credential>[];
    final credential = cards.firstWhereOrNull((c) => c.hash == _hash);
    final animation = _routeAnimation ?? kAlwaysCompleteAnimation;

    final hints = ref.watch(instanceHintsProvider);
    final hintText = credential == null
        ? null
        : instanceHintText(context, hints[_hash] ?? const NoHint());

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Transparent while the data tab moves away, opaque once open.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => ColoredBox(
                color: palette.background.withValues(
                  alpha: const Interval(0.6, 1).transform(animation.value),
                ),
              ),
            ),
          ),
          if (credential != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 32).clamp(0.0, 460.0);
                  return ListView(
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
                      _Reveal(
                        animation: animation,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: _Details(
                              credential: credential,
                              siblings: cards
                                  .where(
                                    (c) =>
                                        c.credentialId ==
                                        credential.credentialId,
                                  )
                                  .toList(),
                              hintTexts: {
                                for (final c in cards)
                                  c.hash: instanceHintText(
                                    context,
                                    hints[c.hash] ?? const NoHint(),
                                  ),
                              },
                              onSwitch: _switchTo,
                              onDeleted: _close,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          // Fades the content out under the floating Done button.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: padding.top + 72,
            child: IgnorePointer(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.6, 1),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.background,
                        palette.background.withValues(alpha: 0),
                      ],
                      stops: const [0.45, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: padding.top + 16,
            right: 16,
            // Faded by the glass itself: a FadeTransition would darken its
            // blur until the fade ends (see GlassSurface.opacity).
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => GlassPillButton(
                buttonKey: const Key("credential_detail_done"),
                label: FlutterI18n.translate(context, "wallet.detail.done"),
                onTap: _close,
                opacity: const Interval(0.4, 1).transform(animation.value),
              ),
            ),
          ),
        ],
      ),
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
    final padding = MediaQuery.paddingOf(context);
    final cards =
        ref.watch(schemalessCredentialOrderControllerProvider).value ??
        const <schemaless.Credential>[];
    final credential = cards.firstWhereOrNull((c) => c.hash == hash);
    if (credential == null) return const SizedBox.shrink();

    final hints = ref.watch(instanceHintsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 64).clamp(0.0, 460.0);
        return ListView(
          key: Key("credential_detail_pane_$hash"),
          padding: EdgeInsets.fromLTRB(
            32,
            padding.top + 32,
            32,
            padding.bottom + 32,
          ),
          children: [
            Center(
              child: CredentialCardArt(
                credential: credential,
                width: width,
                hintText: instanceHintText(
                  context,
                  hints[hash] ?? const NoHint(),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: _Details(
                  credential: credential,
                  siblings: cards
                      .where((c) => c.credentialId == credential.credentialId)
                      .toList(),
                  hintTexts: {
                    for (final c in cards)
                      c.hash: instanceHintText(
                        context,
                        hints[c.hash] ?? const NoHint(),
                      ),
                  },
                  onSwitch: onSwitch,
                  onDeleted: onDeleted,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Fades its child in and moves it up from below as the route opens.
class _Reveal extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _Reveal({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final opening = animation.status != AnimationStatus.reverse;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = opening
            ? const Interval(
                0.25,
                1,
                curve: WalletTransition.curve,
              ).transform(animation.value)
            : const Interval(0.5, 1).transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, reduceMotion ? 0 : (1 - t) * 56),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _Details extends ConsumerWidget {
  final schemaless.Credential credential;
  final List<schemaless.Credential> siblings;
  final Map<String, String> hintTexts;
  final ValueChanged<String> onSwitch;
  final VoidCallback onDeleted;

  const _Details({
    required this.credential,
    required this.siblings,
    required this.hintTexts,
    required this.onSwitch,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final lang = FlutterI18n.currentLocale(context)?.languageCode ?? "en";
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
                FlutterI18n.translate(
                  context,
                  "credential.issued_by",
                  translationParams: {"issuer": credential.issuer.name},
                ),
                style: palette.body(14).copyWith(color: palette.secondaryText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _validityChip(context, palette, status, lang),
            _Chip(
              label: source,
              background: palette.surface,
              foreground: palette.link,
              outline: palette.outline,
            ),
          ],
        ),
        if (siblings.length > 1) ...[
          heading(
            "wallet.detail.siblings",
            params: {"count": "${siblings.length}"},
          ),
          SizedBox(
            height: 81 + 6 + 10 + 4 + 16,
            child: ListView.separated(
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
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(18),
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
                            shadow: false,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 136,
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
        ],
        heading("wallet.detail.details"),
        _Group(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: YiviCredentialCardAttributeList(
            credential.attributes,
            credentialId: credential.credentialId,
            showDividers: true,
          ),
        ),
        if (sharable != null) ...[
          heading("credential.sharable"),
          _Group(
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
        _Group(
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
            label: FlutterI18n.translate(
              context,
              "credential.options.reobtain",
            ),
            onPressed: () => IrmaRepositoryProvider.of(context).openIssueURL(
              context,
              credential.credentialId,
              credential.issueUrl,
              ref,
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
    YiviPalette palette,
    CredentialCardStatus status,
    String lang,
  ) {
    final expiry = status.expiryDate?.dateTime;
    if (status.revoked) {
      return _Chip(
        label: FlutterI18n.translate(context, "credential.revoked"),
        background: palette.errorSurface,
        foreground: palette.errorText,
        icon: Icons.block,
      );
    }
    if (status.isExpired && expiry != null) {
      return _Chip(
        label: FlutterI18n.translate(
          context,
          "credential.expired_on",
          translationParams: {"date": printableDate(expiry, lang)},
        ),
        background: palette.errorSurface,
        foreground: palette.errorText,
        icon: Icons.warning_amber_rounded,
      );
    }
    if (status.hasWarning && expiry != null) {
      return _Chip(
        label: FlutterI18n.translate(
          context,
          "credential.expires_on",
          translationParams: {"date": printableDate(expiry, lang)},
        ),
        background: palette.warningSurface,
        foreground: palette.warningText,
        icon: Icons.schedule,
      );
    }
    return _Chip(
      label: expiry == null
          ? FlutterI18n.translate(context, "wallet.detail.valid_indefinitely")
          : FlutterI18n.translate(
              context,
              "wallet.detail.valid_until",
              translationParams: {"date": printableDate(expiry, lang)},
            ),
      background: palette.successSurface,
      foreground: palette.successText,
      icon: Icons.check,
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => DeleteCredentialConfirmationDialog(),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    final toast = appToastFor(context);
    final message = FlutterI18n.translate(
      context,
      "credential.options.delete_success",
    );
    IrmaRepositoryProvider.of(context).bridgedDispatch(
      DeleteCredentialEvent(hashByFormat: credential.credentialInstanceIds),
    );
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

class _Group extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Group({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRSuperellipse(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color? outline;
  final IconData? icon;

  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
    this.outline,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: EdgeInsets.fromLTRB(icon == null ? 12 : 8, 4, 12, 4),
      decoration: ShapeDecoration(
        color: background,
        shape: StadiumBorder(
          side: outline == null ? BorderSide.none : BorderSide(color: outline!),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (icon != null) Icon(icon, size: 14, color: foreground),
          Flexible(
            child: Text(
              label,
              style: palette
                  .body(12, weight: FontWeight.w600)
                  .copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Row(
        spacing: 16,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.tint,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history, size: 20, color: palette.link),
          ),
          Expanded(
            child: Text(
              title,
              style: palette.body(14, weight: FontWeight.w600),
            ),
          ),
          Text(
            date,
            style: palette.body(12).copyWith(color: palette.secondaryText),
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
