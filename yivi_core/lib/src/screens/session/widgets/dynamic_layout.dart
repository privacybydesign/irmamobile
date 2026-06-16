import "package:flutter/material.dart";

import "../../../theme/theme.dart";
import "../../../widgets/irma_bottom_bar_base.dart";

class DynamicLayout extends StatelessWidget {
  final Widget hero;
  final Widget content;
  final List<Widget>? actions;

  const DynamicLayout({
    required this.hero,
    required this.content,
    required this.actions,
  });

  Row _buildButtonsRow(BuildContext context, List<Widget> actions) {
    final List<Widget> rowChildren = [];
    for (var action in actions) {
      rowChildren.add(Expanded(child: action));
      if (action != actions.last) {
        rowChildren.add(SizedBox(width: context.yivi.smallSpacing));
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rowChildren,
    );
  }

  Padding _buildLandscapeLayout(
    BuildContext context,
    BoxConstraints constraints,
    bool isSmallScreen,
  ) {
    final actions = this.actions;

    return Padding(
      padding: EdgeInsets.all(context.yivi.defaultSpacing),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: hero),
            SizedBox(width: context.yivi.smallSpacing),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(child: content),
                        ),
                      ),
                      if (actions != null)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            padding: EdgeInsets.only(
                              bottom: context.yivi.defaultSpacing,
                            ),
                            child: _buildButtonsRow(context, actions),
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
  }

  ConstrainedBox _buildPortraitLayout(
    BuildContext context,
    Size screenSize,
    BoxConstraints constraints,
    bool isSmallScreen,
  ) {
    final actions = this.actions;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: constraints.maxHeight),
      child: IntrinsicHeight(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(
                isSmallScreen
                    ? context.yivi.defaultSpacing
                    : context.yivi.largeSpacing,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  hero,
                  SizedBox(height: context.yivi.mediumSpacing),
                  Row(children: [Expanded(child: content)]),
                  if (actions != null) const SizedBox(height: 100),
                ],
              ),
            ),
            if (actions != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: IrmaBottomBarBase(
                  child: _buildButtonsRow(context, actions),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isSmallScreen = mediaQuery.size.height < 670;

    return LayoutBuilder(
      builder: ((context, constraints) => isLandscape
          ? _buildLandscapeLayout(context, constraints, isSmallScreen)
          : _buildPortraitLayout(
              context,
              mediaQuery.size,
              constraints,
              isSmallScreen,
            )),
    );
  }
}
