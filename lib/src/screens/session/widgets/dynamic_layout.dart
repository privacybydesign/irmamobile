import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_bottom_bar_base.dart';

class DynamicLayout extends StatelessWidget {
  final Widget hero;
  final Widget content;
  final List<Widget>? actions;

  const DynamicLayout({
    required this.hero,
    required this.content,
    required this.actions,
  });

  Row _buildButtonsRow(IrmaThemeData theme) {
    final List<Widget> rowChildren = [];
    for (var action in actions!) {
      rowChildren.add(Expanded(child: action));
      if (action != actions!.last) {
        rowChildren.add(SizedBox(width: theme.smallSpacing));
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rowChildren,
    );
  }

  _buildLandscapeLayout(
    IrmaThemeData theme,
    BoxConstraints constraints,
    bool isSmallScreen,
  ) =>
      Padding(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: hero,
              ),
              SizedBox(
                width: theme.smallSpacing,
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              child: content,
                            ),
                          ),
                        ),
                        if (actions != null)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              padding: EdgeInsets.only(bottom: theme.defaultSpacing),
                              child: _buildButtonsRow(theme),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  _buildPortraitLayout(
    IrmaThemeData theme,
    Size screenSize,
    BoxConstraints constraints,
    bool isSmallScreen,
  ) =>
      ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(
                  isSmallScreen ? theme.defaultSpacing : theme.largeSpacing,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    hero,
                    SizedBox(height: theme.defaultSpacing),
                    content,
                    if (actions != null) const SizedBox(height: 100)
                  ],
                ),
              ),
              if (actions != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: IrmaBottomBarBase(
                    child: _buildButtonsRow(theme),
                  ),
                ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isSmallScreen = mediaQuery.size.height < 670;

    return LayoutBuilder(
      builder: ((context, constraints) => isLandscape
          ? _buildLandscapeLayout(theme, constraints, isSmallScreen)
          : _buildPortraitLayout(theme, mediaQuery.size, constraints, isSmallScreen)),
    );
  }
}
