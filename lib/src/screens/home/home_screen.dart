import 'package:flutter/material.dart';

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
    return Scaffold(
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
    );
  }
}
