part of "data_tab.dart";

/// The view (Stack, List, Grid) and "Arrange" in one menu, under a button
/// that says which view is shown. Arranging tidies the cards up once, by
/// name, newest first or by issuer: there is one order, the user's, and
/// what comes out is simply that, to drag on from. A toast says what
/// happened and can undo it.
class _ViewMenu extends ConsumerWidget {
  final WalletView view;
  final bool arrangeable;

  const _ViewMenu({required this.view, required this.arrangeable});

  static const _viewIcons = {
    WalletView.stack: Icons.view_agenda_outlined,
    WalletView.list: Icons.view_list_rounded,
    WalletView.grid: Icons.grid_view_rounded,
  };

  static const _arrangeIcons = {
    CardArrangement.name: Icons.sort_by_alpha_rounded,
    CardArrangement.newest: Icons.schedule_rounded,
    CardArrangement.issuer: Icons.account_balance_outlined,
  };

  /// What a screen reader says for the menu's button: "View: Stack".
  static String _semanticsLabel(BuildContext context, WalletView view) =>
      "${context.tr("wallet.view.label")}: "
      "${context.tr("wallet.view.${view.name}")}";

  Future<void> _open(BuildContext context, WidgetRef ref) =>
      open(context, ref, view: view, arrangeable: arrangeable);

  /// The menu, under the button at [context].
  static Future<void> open(
    BuildContext context,
    WidgetRef ref, {
    required WalletView view,
    required bool arrangeable,
  }) async {
    final picked = await showGlassMenu<Object>(
      context,
      items: [
        for (final (i, v) in WalletView.values.indexed)
          GlassMenuItem(
            key: Key("wallet_view_${v.name}"),
            value: v,
            label: context.tr("wallet.view.${v.name}"),
            icon: _viewIcons[v]!,
            section: i == 0 ? context.tr("wallet.view.label") : null,
            checked: v == view,
          ),
        if (arrangeable)
          for (final (i, way) in CardArrangement.values.indexed)
            GlassMenuItem(
              key: Key("wallet_arrange_${way.name}"),
              value: way,
              label: context.tr("wallet.arrange.${way.name}"),
              icon: _arrangeIcons[way]!,
              section: i == 0 ? context.tr("wallet.arrange.button") : null,
            ),
      ],
      footnote: arrangeable ? context.tr("wallet.arrange.hint") : null,
    );
    if (!context.mounted) return;
    switch (picked) {
      case final WalletView v:
        ref.read(walletViewProvider.notifier).set(v);
      case final CardArrangement by:
        final order = ref.read(credentialOrderControllerProvider.notifier);
        final before = order.arrange(by);
        Haptics.drop();
        showAppToast(
          context,
          context.tr("wallet.arrange.done_${by.name}"),
          key: const Key("wallet_arrange_toast"),
          overTabBar: true,
          action: (
            label: context.tr("wallet.arrange.undo"),
            onTap: () => order.restore(before),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final label = context.tr("wallet.view.${view.name}");
    return Semantics(
      button: true,
      label: _semanticsLabel(context, view),
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key("wallet_arrange"),
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context, ref),
        child: PressScale(
          // A finger's room around the 36 high pill.
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: YiviSpace.x4),
            child: Container(
              height: 36,
              padding: const EdgeInsetsDirectional.only(
                start: 10,
                end: YiviSpace.x8,
              ),
              decoration: ShapeDecoration(
                color: palette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  side: BorderSide(color: palette.divider),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Icon(_viewIcons[view], size: 18, color: palette.text),
                  Text(
                    label,
                    maxLines: 1,
                    style: palette.display(14).copyWith(color: palette.text),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: palette.text,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The view menu's button at the top left of the phone's bar: "…", for the
/// view (Stack, List, Grid) and arranging the cards. Nothing without cards.
class _ViewMenuButton extends ConsumerWidget {
  const _ViewMenuButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(walletCardsProvider).length;
    if (count == 0) return const SizedBox.shrink();
    final view = ref.watch(walletViewProvider) ?? WalletView.stack;
    return YiviIconButton(
      key: const Key("wallet_arrange"),
      icon: CupertinoIcons.ellipsis,
      label: _ViewMenu._semanticsLabel(context, view),
      onTap: () =>
          _ViewMenu.open(context, ref, view: view, arrangeable: count > 1),
      look: IconButtonLook.bar,
    );
  }
}
