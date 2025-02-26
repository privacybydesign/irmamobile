import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/native_events.dart';
import '../../theme/theme.dart';
import '../../util/navigation.dart';
import '../../util/rounded_display.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import '../activity/activity_tab.dart';
import '../data/data_tab.dart';
import '../more/more_tab.dart';
import '../notifications/bloc/notifications_bloc.dart';
import '../notifications/widgets/notification_bell.dart';
import '../scanner/util/open_scanner.dart';
import 'home_tab.dart';
import 'widgets/irma_nav_bar.dart';
import 'widgets/irma_qr_scan_button.dart';
import 'widgets/pending_pointer_listener.dart';

/// Having different transition types causes separate instances of the HomeScreen to be created.
/// In order to keep the selected tab state across these instances, we move
/// the state outside of the HomeScreen widget and into this Bloc.
class HomeTabState extends Bloc<IrmaNavBarTab, IrmaNavBarTab> {
  HomeTabState() : super(IrmaNavBarTab.home);

  @override
  Stream<IrmaNavBarTab> mapEventToState(IrmaNavBarTab event) async* {
    yield event;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  void _changeTab(IrmaNavBarTab tab) {
    context.read<HomeTabState>().add(tab);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = IrmaRepositoryProvider.of(context);
      maybeOpenQrScanner(context, repo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return BlocBuilder<HomeTabState, IrmaNavBarTab>(
      builder: (context, tabState) {
        // We wrap this widget in a PopScope to make sure a back press on Android returns the user to the
        // home tab first. If the home tab is already selected, then we cannot go back further. The HomeScreen is the
        // root route in the navigator. In that case, we background the app on Android.
        // On iOS, there is no back button so we don't have to handle this case.
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, popResult) {
            if (tabState == IrmaNavBarTab.home) {
              IrmaRepositoryProvider.of(context).bridgedDispatch(AndroidSendToBackgroundEvent());
            } else {
              _changeTab(IrmaNavBarTab.home);
            }
          },
          child: PendingPointerListener(
            child: Scaffold(
              backgroundColor: IrmaTheme.of(context).backgroundTertiary,
              appBar: IrmaAppBar(
                titleTranslationKey:
                    tabState == IrmaNavBarTab.home ? 'home_tab.title' : 'home.nav_bar.${tabState.name}',
                noLeading: true,
                actions: [
                  BlocBuilder<NotificationsBloc, NotificationsState>(
                    builder: (context, state) => NotificationBell(
                      showIndicator: state is NotificationsLoaded ? state.hasUnreadNotifications : false,
                      onTap: context.goNotificationsScreen,
                    ),
                  )
                ],
              ),
              body: SafeArea(
                child: Builder(
                  builder: (context) {
                    return switch (tabState) {
                      IrmaNavBarTab.home => HomeTab(onChangeTab: _changeTab),
                      IrmaNavBarTab.data => DataTab(),
                      IrmaNavBarTab.activity => ActivityTab(),
                      IrmaNavBarTab.more => MoreTab(onChangeTab: _changeTab),
                    };
                  },
                ),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              floatingActionButton: Padding(
                padding: EdgeInsets.only(bottom: hasRoundedDisplay(context) ? theme.defaultSpacing : 0),
                child: const IrmaQrScanButton(
                  key: Key('nav_button_scanner'),
                ),
              ),
              bottomNavigationBar: IrmaNavBar(
                selectedTab: tabState,
                onChangeTab: _changeTab,
              ),
            ),
          ),
        );
      },
    );
  }
}
