import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../util/rounded_display.dart';
import 'irma_nav_button.dart';

enum IrmaNavBarTab {
  home,
  data,
  activity,
  more,
}

class IrmaNavBar extends StatelessWidget {
  final Function(IrmaNavBarTab tab) onChangeTab;
  final IrmaNavBarTab selectedTab;

  const IrmaNavBar({
    super.key,
    required this.onChangeTab,
    this.selectedTab = IrmaNavBarTab.home,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: theme.tinySpacing,
        right: theme.tinySpacing,
        bottom: hasRoundedDisplay(context) ? theme.defaultSpacing : 0,
      ),
      // Reduce vertical padding for screens with limited height (i.e. landscape mode).
      height: MediaQuery.of(context).size.height > 450 ? 95 : 85,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: theme.tertiary,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade600.withOpacity(0.5),
            blurRadius: 10.0,
            spreadRadius: 1.0,
            offset: const Offset(0, 7),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IrmaNavButton(
            key: const Key('nav_button_home'),
            iconData: selectedTab == IrmaNavBarTab.home ? Icons.home : Icons.home_outlined,
            tab: IrmaNavBarTab.home,
            changeTab: onChangeTab,
            isSelected: IrmaNavBarTab.home == selectedTab,
          ),
          IrmaNavButton(
            key: const Key('nav_button_data'),
            iconData: selectedTab == IrmaNavBarTab.data ? Icons.person : Icons.person_outline,
            tab: IrmaNavBarTab.data,
            changeTab: onChangeTab,
            isSelected: IrmaNavBarTab.data == selectedTab,
          ),
          // Spacing for the QR scan button
          const SizedBox(
            width: 90,
          ),
          IrmaNavButton(
            key: const Key('nav_button_activity'),
            iconData: Icons.history,
            tab: IrmaNavBarTab.activity,
            changeTab: onChangeTab,
            isSelected: IrmaNavBarTab.activity == selectedTab,
          ),
          IrmaNavButton(
            key: const Key('nav_button_more'),
            iconData: Icons.more_horiz,
            tab: IrmaNavBarTab.more,
            changeTab: onChangeTab,
            isSelected: IrmaNavBarTab.more == selectedTab,
          )
        ],
      ),
    );
  }
}
