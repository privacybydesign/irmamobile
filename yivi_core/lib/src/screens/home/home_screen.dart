import "package:flutter_bloc/flutter_bloc.dart";
import "package:material_ui/material_ui.dart";

import "../../models/native_events.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../activity/activity_tab.dart";
import "../data/data_tab.dart";
import "../data/wallet/wallet_transition.dart";
import "../more/more_tab.dart";
import "../notifications/notifications_tab.dart";
import "widgets/glass_sidebar.dart";
import "widgets/glass_tab_bar.dart";
import "widgets/irma_nav_bar.dart";
import "widgets/pending_pointer_listener.dart";

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
              body: isExpandedLayout(context)
                  ? _withSidebar(context, tabState, changeTab)
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
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom:
                              16 + (bottomPadding > 0 ? bottomPadding - 8 : 8),
                          child: PushAway(
                            direction: PushAwayDirection.down,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 640,
                                ),
                                child: GlassTabBar(
                                  selectedTab: tabState,
                                  onChangeTab: changeTab,
                                ),
                              ),
                            ),
                          ),
                        ),
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
