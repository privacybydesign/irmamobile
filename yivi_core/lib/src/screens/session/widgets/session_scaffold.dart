import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
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

  const SessionScaffold({
    Key? key,
    this.onDismiss,
    this.onPrevious,
    this.bottomNavigationBar,
    this.body,
    required this.appBarTitle,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: YiviPalette.of(context).background,
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : _centred(bottomNavigationBar!),
      body: body == null ? null : (wide ? body : _centred(body!)),
      appBar: IrmaAppBar(
        titleTranslationKey: appBarTitle,
        leading: onPrevious != null ? YiviBackButton(onTap: onPrevious) : null,
        actions: [
          if (onDismiss != null)
            Padding(
              padding: EdgeInsets.only(right: theme.defaultSpacing),
              child: IrmaCloseButton.filled(onTap: onDismiss),
            ),
        ],
      ),
    );
  }

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
