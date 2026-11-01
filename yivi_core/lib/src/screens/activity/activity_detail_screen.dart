import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../providers/activity_providers.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../widgets/compact_bar.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/two_pane.dart";
import "activity_entry.dart";
import "activity_query.dart";
import "widgets/activity_detail_parts.dart";

class ActivityDetailsScreenArgs {
  final LogInfo logEntry;

  ActivityDetailsScreenArgs({required this.logEntry});
}

/// The details of one log entry, as an ordinary page: it slides in from
/// the side with a back button, and the back swipe closes it. The hero
/// header runs up under the bar; once the party's name has scrolled under
/// the bar, the bar shows it.
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

  /// Whether the party's name has scrolled under the bar: the bar then
  /// shows it, with its band.
  final _nameUnderBar = ValueNotifier(false);

  final _nameKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Measured after the frame: during the scroll notification the name
    // still has the position of the previous frame.
    _scroll.addListener(
      () => WidgetsBinding.instance.addPostFrameCallback((_) => _checkName()),
    );
  }

  void _checkName() {
    if (!mounted) return;
    final under = headerUnderBar(context, _nameKey);
    if (under != null) _nameUnderBar.value = under;
  }

  @override
  void dispose() {
    _scroll.dispose();
    _nameUnderBar.dispose();
    super.dispose();
  }

  /// "All activity with …": back to the Activity tab, asking about the
  /// party.
  void _ask(ActivityQuery query) {
    ref.read(activityLogProvider.notifier).setFilter(query);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final wallet = ref.watch(walletCardsProvider);
    final entry = ActivityEntry.fromLog(widget.logEntry, wallet: wallet);
    // The name can move (rotation, text size): check again after this
    // layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkName());

    return Scaffold(
      key: const Key("activity_detail_screen"),
      extendBodyBehindAppBar: true,
      backgroundColor: palette.background,
      appBar: IrmaAppBar(
        title: ActivityBarTitle(entry: entry),
        titleVisibility: _nameUnderBar,
        edgeShown: _nameUnderBar,
      ),
      body: ListView(
        controller: _scroll,
        // Short or long, it scrolls (and bounces), as any page.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: padding.bottom + 32),
        children: [
          ActivityDetailBody(
            entry: entry,
            top: padding.top + IrmaAppBar.contentTop,
            nameKey: _nameKey,
            onAsk: _ask,
          ),
        ],
      ),
    );
  }
}

/// The detail pane of the activity tab in the tablet layout: the same
/// content.
class ActivityDetailPane extends ConsumerWidget {
  final LogInfo logEntry;

  const ActivityDetailPane({super.key, required this.logEntry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletCardsProvider);
    final entry = ActivityEntry.fromLog(logEntry, wallet: wallet);
    final padding = paneContentPadding(context);
    return ListView(
      key: Key("activity_detail_pane_${entry.key}"),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: padding.bottom),
      children: [
        ActivityDetailBody(
          entry: entry,
          top: padding.top,
          maxWidth: 560,
          compactHeader: usePhoneLandscape(context),
          onAsk: (query) =>
              ref.read(activityLogProvider.notifier).setFilter(query),
        ),
      ],
    );
  }
}
