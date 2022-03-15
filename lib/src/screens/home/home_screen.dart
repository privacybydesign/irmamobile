import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/home/widgets/app_tab.dart';
import 'package:irmamobile/src/screens/home/widgets/irma_home_nav_bar.dart';

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
          switch (selectedTab) {
            case IrmaNavBarTab.data:
              return const Text('data');
            case IrmaNavBarTab.activity:
              return const Text('activity');
            case IrmaNavBarTab.app:
              return MyAppTab();
            case IrmaNavBarTab.home:
              return const Text('home');
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
