part of "yivi_pin_screen.dart";

/// Explains why [state]'s PIN is possibly not secure: the rules of a secure
/// PIN, each with whether it is met. A sheet in portrait, a full screen in
/// landscape (where a sheet has too little height).
void _showSecurePinRules(BuildContext context, EnterPinState state) {
  final theme = IrmaTheme.of(context);

  // OrientationBuilder builds a widget tree that can depend on the parent
  // widget's orientation (distinct from the device orientation). In this
  // case, OrientationBuilder gives false results. Hence MediaQuery.
  if (MediaQuery.of(context).orientation == Orientation.landscape) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, _) =>
            _UnsecurePinFullScreen(state: state),
      ),
    );
    return;
  }
  showTitledGlassSheet(
    context: context,
    titleKey: "secure_pin.title",
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: theme.screenPadding),
          Text(
            FlutterI18n.translate(context, "secure_pin.subtitle"),
            style: YiviPalette.of(context).body(16),
          ),
          SizedBox(height: theme.screenPadding),
          ..._listBuilder(context, state),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}
