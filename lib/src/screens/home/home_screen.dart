import 'package:flutter/material.dart';

import '../../models/native_events.dart';
import '../../widgets/irma_repository_provider.dart';
import '../activity/activity_tab.dart';
import '../data/data_tab.dart';
import '../more/more_tab.dart';
import 'home_tab.dart';
import 'widgets/irma_nav_bar.dart';
import 'widgets/irma_qr_scan_button.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  IrmaNavBarTab selectedTab = IrmaNavBarTab.home;

  void _changeTab(IrmaNavBarTab tab) => setState(
        () => selectedTab = tab,
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
      child: Scaffold(
        body: SafeArea(
          child: Builder(builder: (context) {
            switch (selectedTab) {
              case IrmaNavBarTab.data:
                return DataTab();
              case IrmaNavBarTab.activity:
                return ActivityTab();
              case IrmaNavBarTab.more:
                return MoreTab();
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
    );
  }
}
