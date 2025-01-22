import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/translated_text.dart';
import 'irma_nav_bar.dart';

final _navBarTabTranslationKeys = {
  IrmaNavBarTab.home: 'home.nav_bar.home',
  IrmaNavBarTab.data: 'home.nav_bar.data',
  IrmaNavBarTab.activity: 'home.nav_bar.activity',
  IrmaNavBarTab.more: 'home.nav_bar.more'
};

final _navBarTabHintKeys = {
  IrmaNavBarTab.home: 'home.nav_bar_hints.home',
  IrmaNavBarTab.data: 'home.nav_bar_hints.data',
  IrmaNavBarTab.activity: 'home.nav_bar_hints.activity',
  IrmaNavBarTab.more: 'home.nav_bar_hints.more'
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

    final activeColor = theme.themeData.colorScheme.primary;
    final inactiveColor = theme.neutralExtraDark;

    return Expanded(
      child: Semantics(
        value: FlutterI18n.translate(context, _navBarTabHintKeys[tab]!),
        child: InkWell(
          onTap: () => changeTab?.call(tab),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconData,
                size: 28,
                color: isSelected ? activeColor : inactiveColor,
              ),
              SizedBox(
                height: theme.tinySpacing,
              ),
              TranslatedText(
                _navBarTabTranslationKeys[tab]!,
                style: theme.themeData.textTheme.titleLarge!.copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
