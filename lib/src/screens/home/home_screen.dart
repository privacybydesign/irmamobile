import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/activity/activity_tab.dart';
import 'package:irmamobile/src/screens/home/home_tab.dart';
import 'package:irmamobile/src/screens/home/widgets/irma_home_nav_bar.dart';
import 'package:irmamobile/src/screens/more/more_tab.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  IrmaNavBarTab selectedTab = IrmaNavBarTab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Builder(builder: (context) {
          //TODO: Replace placeholder values
          switch (selectedTab) {
            case IrmaNavBarTab.data:
              return const Text('data');
            case IrmaNavBarTab.activity:
              return ActivityTab();
            case IrmaNavBarTab.more:
              return MoreTab();
            case IrmaNavBarTab.home:
              return HomeTab();
          }
        }),
        bottomNavigationBar: IrmaNavBar(
            selectedTab: selectedTab,
            onChangeTab: (IrmaNavBarTab tab) {
              setState(() {
                selectedTab = tab;
              });
            }));
  }
}
