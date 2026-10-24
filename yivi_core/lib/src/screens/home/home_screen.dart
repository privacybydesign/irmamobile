import "dart:math";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/native_events.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../widgets/centred_max_width.dart";
import "../../widgets/glass/floating_bar_placement.dart";
import "../activity/activity_tab.dart";
import "../data/data_tab.dart";
import "../data/wallet/wallet_transition.dart";
import "../more/more_tab.dart";
import "../notifications/notifications_tab.dart";
import "widgets/glass_rail.dart";
import "widgets/glass_sidebar.dart";
import "widgets/glass_tab_bar.dart";
import "widgets/irma_nav_bar.dart";
import "widgets/pending_pointer_listener.dart";
import "widgets/scan_tip.dart";

/// Having different transition types causes separate instances of the HomeScreen to be created.
/// In order to keep the selected tab state across these instances, we move
/// the state outside of the HomeScreen widget and into this Bloc.
class HomeTabState extends Bloc<IrmaNavBarTab, IrmaNavBarTab> {
  HomeTabState() : super(.data);

  @override
  Stream<IrmaNavBarTab> mapEventToState(IrmaNavBarTab event) async* {
    yield event;
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    changeTab(IrmaNavBarTab tab) {
      context.read<HomeTabState>().add(tab);
    }

    final palette = YiviPalette.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return BlocBuilder<HomeTabState, IrmaNavBarTab>(
      builder: (context, tabState) {
        // We wrap this widget in a PopScope to make sure a back press on Android returns the user to the
        // home tab first. If the home tab is already selected, then we cannot go back further. The HomeScreen is the
        // root route in the navigator. In that case, we background the app on Android.
        // On iOS, there is no back button so we don't have to handle this case.
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, popResult) {
            if (tabState == .data) {
              IrmaRepositoryProvider.of(
                context,
              ).bridgedDispatch(AndroidSendToBackgroundEvent());
            } else {
              changeTab(.data);
            }
          },
          child: PendingPointerListener(
            child: Scaffold(
              backgroundColor: palette.background,
              resizeToAvoidBottomInset: false,
              body: useSidebar(context)
                  ? _withSidebar(context, tabState, changeTab)
                  : useHomePanes(context)
                  ? _withRail(context, tabState, changeTab)
                  : Stack(
                      children: [
                        Positioned.fill(child: _tab(tabState, changeTab)),
                        // Fades the content out under the floating tab bar.
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 96 + bottomPadding,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    palette.background.withValues(alpha: 0),
                                    palette.background.withValues(alpha: 0.85),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Clear of a side panel (an unfolded phone).
                        Positioned(
                          left: 16 + MediaQuery.paddingOf(context).left,
                          right: 16 + MediaQuery.paddingOf(context).right,
                          bottom: FloatingBarPlacement.tabBarBottom(context),
                          child: PushAway(
                            direction: PushAwayDirection.down,
                            child: CentredMaxWidth(
                              maxWidth: mediumContentMaxWidth,
                              child: GlassTabBar(
                                selectedTab: tabState,
                                onChangeTab: changeTab,
                              ),
                            ),
                          ),
                        ),
                        if (tabState == .data) _scanTipOverBar(context),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _tab(IrmaNavBarTab tab, ValueChanged<IrmaNavBarTab> changeTab) =>
      switch (tab) {
        .notifications => NotificationsTab(),
        .data => DataTab(),
        .activity => ActivityTab(),
        .more => MoreTab(onChangeTab: changeTab),
      };

  /// A phone held sideways, and a tablet below [sidebarBreakpoint]: a
  /// floating rail on the left instead of the tab bar, with the tab (a list
  /// and the picked item's details) beside it.
  Widget _withRail(
    BuildContext context,
    IrmaNavBarTab tab,
    ValueChanged<IrmaNavBarTab> changeTab,
  ) {
    final padding = MediaQuery.paddingOf(context);
    // In the safe area on the notch side; 16 from the edge without a notch.
    final railLeft = padding.left > 0 ? padding.left : 16.0;
    // The tabs keep 16 on their sides: their content starts 12 from the rail.
    final contentLeft = railLeft + GlassRail.width - 4;
    return Stack(
      children: [
        Positioned.fill(
          left: contentLeft,
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            child: _tab(tab, changeTab),
          ),
        ),
        Positioned(
          left: railLeft,
          top: padding.top,
          bottom: padding.bottom,
          width: GlassRail.width,
          child: Center(
            child: GlassRail(selectedTab: tab, onChangeTab: changeTab),
          ),
        ),
        if (tab == .data) _scanTipBesideRail(context, railLeft),
      ],
    );
  }

  /// The first-visit tip above the Scan button, at the right end of the tab
  /// bar (which is centred and at most 640 wide).
  Widget _scanTipOverBar(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final available = width - 32 - padding.left - padding.right;
    return Positioned(
      right:
          16 +
          padding.right +
          max(0.0, (available - mediumContentMaxWidth) / 2),
      bottom: FloatingBarPlacement.tabBarBottom(context) + 64 + 12,
      child: const _ScanTipWhenDue(rail: false),
    );
  }

  /// The first-visit tip beside the rail's Scan button, the bottom of the
  /// rail, which is centred top to bottom.
  Widget _scanTipBesideRail(BuildContext context, double railLeft) {
    final padding = MediaQuery.paddingOf(context);
    final height = MediaQuery.sizeOf(context).height;
    final railMiddle =
        padding.top + (height - padding.top - padding.bottom) / 2;
    final scanMiddle =
        railMiddle + GlassRail.height / 2 - GlassRail.scanButtonSize / 2;
    return Positioned(
      left: railLeft + GlassRail.width + 12,
      top: scanMiddle,
      child: const FractionalTranslation(
        translation: Offset(0, -0.5),
        child: _ScanTipWhenDue(rail: true),
      ),
    );
  }

  /// The tablet layout: the glass sidebar on the left instead of the
  /// floating tab bar.
  Widget _withSidebar(
    BuildContext context,
    IrmaNavBarTab tab,
    ValueChanged<IrmaNavBarTab> changeTab,
  ) {
    final padding = MediaQuery.paddingOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left + 16,
            padding.top + 16,
            16,
            padding.bottom + 16,
          ),
          child: SizedBox(
            width: sidebarWidth,
            child: GlassSidebar(selectedTab: tab, onChangeTab: changeTab),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            child: _tab(tab, changeTab),
          ),
        ),
      ],
    );
  }
}

class _ScanTipWhenDue extends ConsumerWidget {
  final bool rail;

  const _ScanTipWhenDue({required this.rail});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(scanTipVisibleProvider)
      ? ScanTip(rail: rail)
      : const SizedBox.shrink();
}
