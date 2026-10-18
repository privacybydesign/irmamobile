import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../providers/schemaless_credentials_list_provider.dart";
import "../data/wallet/wallet_detail_scaffold.dart";
import "activity_entry.dart";
import "widgets/activity_detail_parts.dart";

class ActivityDetailsScreenArgs {
  final LogInfo logEntry;

  ActivityDetailsScreenArgs({required this.logEntry});
}

/// The details of one log entry. Opens with the Wallet-style transition: the
/// cards of the row's stack fly into their tiles while the activity list
/// moves away, then the rest fades up. Pull down, Done, or a tap on a card
/// closes it again.
class ActivityDetailsScreen extends ConsumerStatefulWidget {
  final LogInfo logEntry;

  ActivityDetailsScreen({required ActivityDetailsScreenArgs args})
    : logEntry = args.logEntry;

  @override
  ConsumerState<ActivityDetailsScreen> createState() =>
      _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends ConsumerState<ActivityDetailsScreen> {
  final _scroll = ScrollController();

  /// Whether the pass header has scrolled away under the top bar.
  final _scrolledPast = ValueNotifier(false);

  /// About the height of the pass header.
  static const _headerHeight = 170.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      _scrolledPast.value = _scroll.offset > _headerHeight;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _scrolledPast.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final wallet =
        ref.watch(schemalessCredentialOrderControllerProvider).value ??
        const <schemaless.Credential>[];
    final entry = ActivityEntry.fromLog(widget.logEntry, wallet: wallet);

    return WalletDetailScaffold(
      openKey: entry.key,
      doneKey: const Key("activity_detail_done"),
      barBuilder: (context, opacity) => ValueListenableBuilder<bool>(
        valueListenable: _scrolledPast,
        builder: (context, shown, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: shown ? 1 : 0),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          builder: (context, t, _) => t == 0
              ? const SizedBox.shrink()
              : IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * -8),
                    child: ActivityCompactBar(
                      entry: entry,
                      opacity: opacity * t,
                    ),
                  ),
                ),
        ),
      ),
      builder: (context, physics, animation) => ListView(
        controller: _scroll,
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ActivityDetailBody(
                entry: entry,
                animation: animation,
                heroes: true,
                onArtTap: _close,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The detail pane of the activity tab in the tablet layout: the same
/// content, without the transition.
class ActivityDetailPane extends ConsumerWidget {
  final LogInfo logEntry;

  const ActivityDetailPane({super.key, required this.logEntry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet =
        ref.watch(schemalessCredentialOrderControllerProvider).value ??
        const <schemaless.Credential>[];
    final entry = ActivityEntry.fromLog(logEntry, wallet: wallet);
    return ListView(
      key: Key("activity_detail_pane_${entry.key}"),
      padding: const EdgeInsets.all(32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ActivityDetailBody(entry: entry),
          ),
        ),
      ],
    );
  }
}
