import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/native_events.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import '../activity/activity_tab.dart';
import '../data/data_tab.dart';
import '../more/more_tab.dart';
import '../notifications/bloc/notifications_bloc.dart';
import '../notifications/notifications_screen.dart';
import '../notifications/widgets/notification_bell.dart';
import '../scanner/util/open_scanner.dart';
import 'home_tab.dart';
import 'widgets/irma_nav_bar.dart';
import 'widgets/irma_qr_scan_button.dart';
import 'widgets/pending_pointer_listener.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => NotificationsBloc(
          repo: IrmaRepositoryProvider.of(context),
        )..add(Initialize()),
        child: _ProvidedHomeScreen(),
      );
}

class _ProvidedHomeScreen extends StatefulWidget {
  @override
  State<_ProvidedHomeScreen> createState() => _ProvidedHomeScreenState();
}

class _ProvidedHomeScreenState extends State<_ProvidedHomeScreen> {
  IrmaNavBarTab selectedTab = IrmaNavBarTab.home;

  void _changeTab(IrmaNavBarTab tab) => setState(
        () => selectedTab = tab,
      );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = IrmaRepositoryProvider.of(context);
      final navigator = Navigator.of(context);

      maybeOpenQrScanner(repo, navigator);
    });
  }

  void _navToNotificationsScreen() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: BlocProvider.of<NotificationsBloc>(context),
            child: NotificationsScreen(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // We wrap this widget in a WillPopScope to make sure a back press on Android returns the user to the
    // home tab first. If the home tab is already selected, then we cannot go back further. The HomeScreen is the
    // root route in the navigator. In that case, we background the app on Android.
    // On iOS, there is no back button so we don't have to handle this case.
    return WillPopScope(
      onWillPop: () async {
        if (selectedTab == IrmaNavBarTab.home) {
          IrmaRepositoryProvider.of(context).bridgedDispatch(AndroidSendToBackgroundEvent());
        } else {
          setState(() {
            selectedTab = IrmaNavBarTab.home;
          });
        }
        return false;
      },
      child: PendingPointerListener(
        child: Scaffold(
          backgroundColor: IrmaTheme.of(context).backgroundTertiary,
          appBar: IrmaAppBar(
            titleTranslationKey:
                selectedTab == IrmaNavBarTab.home ? 'home_tab.title' : 'home.nav_bar.${selectedTab.name}',
            noLeading: true,
            actions: [
              BlocBuilder<NotificationsBloc, NotificationsState>(
                builder: (context, state) {
                  return NotificationBell(
                    showIndicator: state is NotificationsLoaded ? state.notifications.isNotEmpty : false,
                    onTap: _navToNotificationsScreen,
                  );
                },
              )
            ],
          ),
          body: SafeArea(
            child: Builder(builder: (context) {
              switch (selectedTab) {
                case IrmaNavBarTab.data:
                  return DataTab();
                case IrmaNavBarTab.activity:
                  return ActivityTab();
                case IrmaNavBarTab.more:
                  return MoreTab(
                    onChangeTab: _changeTab,
                  );
                case IrmaNavBarTab.home:
                  return HomeTab(
                    onChangeTab: _changeTab,
                  );
              }
            }),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: const IrmaQrScanButton(
            key: Key('nav_button_scanner'),
          ),
          bottomNavigationBar: IrmaNavBar(
            selectedTab: selectedTab,
            onChangeTab: _changeTab,
          ),
        ),
      ),
    );
  }
}
