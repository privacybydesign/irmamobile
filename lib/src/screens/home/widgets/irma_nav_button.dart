import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/translated_text.dart';
import 'irma_nav_bar.dart';

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

  const IrmaNavButton({
    Key? key,
    required this.iconData,
    required this.tab,
    this.isSelected = false,
    this.changeTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Expanded(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: () => changeTab?.call(tab),
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
              TranslatedText(
                _navBarTabTranslationKeys[tab]!,
                style: theme.themeData.textTheme.caption!.copyWith(
                  fontSize: 12,
                  color: isSelected ? theme.themeData.colorScheme.secondary : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
