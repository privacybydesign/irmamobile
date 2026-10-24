import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/log_entry.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../util/adaptive_layout.dart";
import "../../widgets/compact_bar.dart";
import "../../widgets/two_pane.dart";
import "../data/wallet/wallet_detail_scaffold.dart";
import "activity_entry.dart";
import "activity_flight.dart";
import "widgets/activity_detail_parts.dart";

class ActivityDetailsScreenArgs {
  final LogInfo logEntry;

  ActivityDetailsScreenArgs({required this.logEntry});
}

/// The details of one log entry. Opens with the Wallet-style transition: the
/// cards of the row's stack fly into their tiles ([ActivityFlight]) while the
/// activity list moves away, then the rest fades up. Pull down, Done, or a tap on a card
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

  /// Whether the header has scrolled away under the top bar: then the
  /// compact bar shows who and when instead.
  final _scrolledPast = ValueNotifier(false);

  final _headerKey = GlobalKey();

  /// The entry as last built, for the flight.
  ActivityEntry? _entry;
  bool _flightStarted = false;

  @override
  void initState() {
    super.initState();
    // Measured after the frame: during the scroll notification the header
    // still has the position of the previous frame.
    _scroll.addListener(
      () => WidgetsBinding.instance.addPostFrameCallback((_) => _checkHeader()),
    );
  }

  /// The header grows when a long name or the date and time pills wrap.
  void _checkHeader() {
    if (!mounted) return;
    final under = headerUnderBar(context, _headerKey);
    if (under != null) _scrolledPast.value = under;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_flightStarted) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null) return;
    _flightStarted = true;
    // After the first frame: the tiles are laid out, and the overlay is not
    // changed while the tree builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final entry = _entry;
      if (!mounted || entry == null) return;
      ActivityFlight.start(context, entry, animation);
    });
  }

  @override
  void dispose() {
    ActivityFlight.stop();
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
    _entry = entry;
    // The header can change size (rotation, text size): check again after
    // this layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkHeader());

    return WalletDetailScaffold(
      openKey: entry.key,
      closeKey: const Key("activity_detail_done"),
      barBuilder: (context, opacity) => CompactBarDropIn(
        shown: _scrolledPast,
        bar: (t) => ActivityCompactBar(entry: entry, opacity: opacity * t),
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
                flight: true,
                onArtTap: _close,
                headerKey: _headerKey,
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
      padding: paneContentPadding(context),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ActivityDetailBody(
              entry: entry,
              compactHeader: usePhoneLandscape(context),
            ),
          ),
        ),
      ],
    );
  }
}
