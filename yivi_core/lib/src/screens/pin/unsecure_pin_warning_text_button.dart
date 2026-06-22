part of "yivi_pin_screen.dart";

class _UnsecurePinWarningTextButton extends StatelessWidget {
  final EnterPinState state;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final BuildContext context;

  _UnsecurePinWarningTextButton({
    required this.scaffoldKey,
    required this.state,
  }) : context = scaffoldKey.currentContext!;

  void _showSecurePinRules(EnterPinState state) {
    final theme = IrmaTheme.of(context);

    // OrientationBuilder builds a widget tree that can depend on
    // the parent widget's orientation (distinct from the device orientation).
    // In this case, OrientationBuilder gives false results. Hence MediaQuery.
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (BuildContext context, _, __) =>
              _UnsecurePinFullScreen(state: state),
        ),
      );
    } else {
      showYiviBottomSheet(
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
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: theme.screenPadding),
              ..._listBuilder(context, state),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Center(
      child: TextButton(
        onPressed: () => _showSecurePinRules(state),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              FlutterI18n.translate(context, "secure_pin.info_button"),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2.0),
            Icon(Icons.info_outlined, color: theme.warning),
          ],
        ),
      ),
    );
  }
}
