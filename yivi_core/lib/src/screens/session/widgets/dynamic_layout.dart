import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
import "../../../theme/yivi_space.dart";
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

  Row _buildButtonsRow(IrmaThemeData theme, List<Widget> actions) {
    final List<Widget> rowChildren = [];
    for (var action in actions) {
      rowChildren.add(Expanded(child: action));
      if (action != actions.last) {
        rowChildren.add(const SizedBox(width: YiviSpace.x8));
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rowChildren,
    );
  }

  Padding _buildLandscapeLayout(
    IrmaThemeData theme,
    BoxConstraints constraints,
    bool isSmallScreen,
  ) {
    final actions = this.actions;

    return Padding(
      padding: const EdgeInsets.all(YiviSpace.x16),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: hero),
            const SizedBox(width: YiviSpace.x8),
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
                            padding: const EdgeInsets.only(
                              bottom: YiviSpace.x16,
                            ),
                            child: _buildButtonsRow(theme, actions),
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
    IrmaThemeData theme,
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
                isSmallScreen ? YiviSpace.x16 : YiviSpace.x32,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  hero,
                  const SizedBox(height: YiviSpace.x24),
                  Row(children: [Expanded(child: content)]),
                  if (actions != null) const SizedBox(height: 100),
                ],
              ),
            ),
            if (actions != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: IrmaBottomBarBase(
                  child: _buildButtonsRow(theme, actions),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isSmallScreen = mediaQuery.size.height < 670;

    return LayoutBuilder(
      builder: ((context, constraints) => isLandscape
          ? _buildLandscapeLayout(theme, constraints, isSmallScreen)
          : _buildPortraitLayout(
              theme,
              mediaQuery.size,
              constraints,
              isSmallScreen,
            )),
    );
  }
}
