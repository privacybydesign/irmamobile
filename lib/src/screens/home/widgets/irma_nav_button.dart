import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/home/widgets/irma_nav_bar.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

final _navBarTabTranslationKeys = {
  IrmaNavBarTab.home: 'home.nav_bar.home',
  IrmaNavBarTab.data: 'home.nav_bar.data',
  IrmaNavBarTab.activity: 'home.nav_bar.activity',
  IrmaNavBarTab.more: 'home.nav_bar.more'
};

class IrmaNavButton extends StatelessWidget {
  final IconData iconData;
  final IrmaNavBarTab tab;
  final bool isSelected;
  final Function(IrmaNavBarTab tab)? changeTab;

  const IrmaNavButton({Key? key, required this.iconData, required this.tab, this.isSelected = false, this.changeTab})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Expanded(
      child: InkWell(
        onTap: () {
          if (changeTab != null) {
            changeTab!(tab);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 28,
              color: isSelected ? theme.themeData.colorScheme.secondary : Colors.grey.shade600,
            ),
            SizedBox(
              height: theme.tinySpacing,
            ),
            TranslatedText(_navBarTabTranslationKeys[tab],
                style: theme.themeData.textTheme.caption!.copyWith(
                    fontSize: 12, color: isSelected ? theme.themeData.colorScheme.secondary : Colors.grey.shade600))
          ],
        ),
      ),
    );
  }
}
