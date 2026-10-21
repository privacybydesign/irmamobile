part of "yivi_pin_screen.dart";

/// The page around a PIN screen: the app bar and the background. The bottom
/// of the safe area is left to the PIN screen, which sets the link under the
/// keypad right on it; on a tablet the PIN screen centres itself.
class YiviPinScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;

  const YiviPinScaffold({super.key, required this.body, this.appBar});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final paddingSize = theme.screenPadding;

    return Scaffold(
      appBar: appBar,
      backgroundColor: YiviPalette.of(context).background,
      body: SafeArea(
        bottom: false,
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(
            left: paddingSize,
            right: paddingSize,
            top: appBar != null ? 0 : paddingSize,
          ),
          child: body,
        ),
      ),
    );
  }
}
