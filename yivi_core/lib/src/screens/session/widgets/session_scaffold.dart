import "package:flutter/foundation.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_close_button.dart";

class SessionScaffold extends StatelessWidget {
  final Widget? body, bottomNavigationBar;
  final String appBarTitle;
  final VoidCallback? onDismiss;
  final VoidCallback? onPrevious;

  /// The body spans the whole width, for the two-column tablet layouts
  /// ([SessionColumns]) that centre themselves.
  final bool wide;

  /// The body pads its own scrolling content for the floating bars (with
  /// [BarInsets]), so it scrolls underneath them. Otherwise the body is
  /// kept between the bars.
  final bool scrollsUnderBars;

  /// For a body that starts with a large title (`LargeTitleScrollView`):
  /// the bar's title shows only while this is true.
  final ValueListenable<bool>? barTitleVisibility;

  /// A glass pill in the bar in place of the title (see
  /// [IrmaAppBar.startBar]).
  final Widget? startBar;

  /// Landscape with a panel at the left: the close button in the corner, 16
  /// from the edge, and no scroll edge band (see [IrmaAppBar.edgeActions]).
  final bool cornerClose;

  const SessionScaffold({
    Key? key,
    this.onDismiss,
    this.onPrevious,
    this.bottomNavigationBar,
    this.body,
    required this.appBarTitle,
    this.wide = false,
    this.scrollsUnderBars = false,
    this.barTitleVisibility,
    this.startBar,
    this.cornerClose = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: YiviPalette.of(context).background,
      // A wide body lays its bar out itself (the landscape result screens
      // put their button at the right).
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : wide
          ? bottomNavigationBar
          : _centred(bottomNavigationBar!),
      body: body == null ? null : _keepClear(wide ? body! : _centred(body!)),
      appBar: IrmaAppBar(
        titleTranslationKey: appBarTitle,
        titleVisibility: barTitleVisibility,
        startBar: startBar,
        edgeActions: cornerClose,
        edge: !cornerClose,
        leading: onPrevious != null ? YiviBackButton(onTap: onPrevious) : null,
        actions: [
          if (onDismiss != null) IrmaCloseButton.filled(onTap: onDismiss),
        ],
      ),
    );
  }

  Widget _keepClear(Widget body) =>
      scrollsUnderBars ? body : SafeArea(child: body);

  /// Keeps the session content in a readable column on tablets.
  static Widget _centred(Widget child) => LayoutBuilder(
    builder: (context, constraints) {
      final side = constraints.maxWidth.isFinite
          ? ((constraints.maxWidth - _maxContentWidth) / 2).clamp(0.0, 1e9)
          : 0.0;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: side),
        child: child,
      );
    },
  );

  static const double _maxContentWidth = 720;
}
