import "dart:async";

import "package:flutter_bloc/flutter_bloc.dart";
import "package:material_ui/material_ui.dart";

import "../../models/clear_all_data_event.dart";
import "../../models/event.dart";
import "../../models/native_events.dart";
import "../../providers/irma_repository_provider.dart";
import "../activity/activity_tab.dart";
import "../data/data_tab.dart";
import "../more/more_tab.dart";
import "../notifications/notifications_tab.dart";
import "widgets/irma_nav_bar.dart";
import "widgets/irma_qr_scan_button.dart";
import "widgets/pending_pointer_listener.dart";

/// Having different transition types causes separate instances of the HomeScreen to be created.
/// In order to keep the selected tab state across these instances, we move
/// the state outside of the HomeScreen widget and into this Bloc.
///
/// Deleting all data goes back to the data tab, so the app opens there after
/// enrolling again, as it does after a fresh install. Without
/// [repositoryEvents] the tab only changes when told to.
class HomeTabState extends Bloc<IrmaNavBarTab, IrmaNavBarTab> {
  HomeTabState({Stream<Event>? repositoryEvents}) : super(.data) {
    _clearAllData = repositoryEvents
        ?.where((event) => event is ClearAllDataEvent)
        .listen((_) => add(.data));
  }

  StreamSubscription<Event>? _clearAllData;

  @override
  Stream<IrmaNavBarTab> mapEventToState(IrmaNavBarTab event) async* {
    yield event;
  }

  @override
  Future<void> close() async {
    await _clearAllData?.cancel();
    return super.close();
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    changeTab(IrmaNavBarTab tab) {
      context.read<HomeTabState>().add(tab);
    }

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
            child: Container(
              color: Colors.white,
              child: SafeArea(
                left: false,
                right: false,
                top: false,
                child: Scaffold(
                  body: switch (tabState) {
                    .notifications => NotificationsTab(),
                    .data => DataTab(),
                    .activity => ActivityTab(),
                    .more => MoreTab(onChangeTab: changeTab),
                  },
                  floatingActionButtonLocation: .centerDocked,
                  resizeToAvoidBottomInset: false,
                  floatingActionButton: Padding(
                    padding: const .only(bottom: 6),
                    child: const IrmaQrScanButton(
                      key: Key("nav_button_scanner"),
                    ),
                  ),
                  bottomNavigationBar: IrmaNavBar(
                    selectedTab: tabState,
                    onChangeTab: changeTab,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
