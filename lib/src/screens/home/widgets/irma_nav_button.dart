import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/translated_text.dart';
import 'irma_nav_bar.dart';

final _navBarTabTranslationKeys = {
  IrmaNavBarTab.data: 'home.nav_bar.data',
  IrmaNavBarTab.activity: 'home.nav_bar.activity',
  IrmaNavBarTab.notifications: 'home.nav_bar.notifications',
  IrmaNavBarTab.more: 'home.nav_bar.more'
};

final _navBarTabHintKeys = {
  IrmaNavBarTab.data: 'home.nav_bar_hints.data',
  IrmaNavBarTab.activity: 'home.nav_bar_hints.activity',
  IrmaNavBarTab.notifications: 'home.nav_bar_hints.notifications',
  IrmaNavBarTab.more: 'home.nav_bar_hints.more'
};

class IrmaNavButton extends StatelessWidget {
  final IconData? iconData;
  final IrmaNavBarTab tab;
  final bool isSelected;
  final Function(IrmaNavBarTab tab)? changeTab;
  final Widget Function(bool active, Color color)? builder;

  const IrmaNavButton({
    super.key,
    this.iconData,
    required this.tab,
    this.isSelected = false,
    this.changeTab,
    this.builder,
  }) : assert((builder == null && iconData != null) || (builder != null && iconData == null),
            'one of them should have a value, but not both');

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
              if (builder != null)
                builder!.call(isSelected, isSelected ? activeColor : inactiveColor)
              else
                Icon(
                  iconData!,
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
