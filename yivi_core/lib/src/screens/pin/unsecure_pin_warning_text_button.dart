part of "yivi_pin_screen.dart";

class _UnsecurePinWarningTextButton extends StatelessWidget {
  final EnterPinState state;

  /// Null on pin screens that only reserve this slot's height (confirm/unlock);
  /// there the button is never shown, so no scaffold context is needed.
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const _UnsecurePinWarningTextButton({
    required this.scaffoldKey,
    required this.state,
  });

  void _showSecurePinRules(BuildContext context, EnterPinState state) {
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
          padding: EdgeInsets.symmetric(horizontal: context.yivi.spacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: context.yivi.spacing.screenPadding),
              Text(
                FlutterI18n.translate(context, "secure_pin.subtitle"),
                style: context.text.bodyMedium,
              ),
              SizedBox(height: context.yivi.spacing.screenPadding),
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
    // Use the scaffold's context (not this subtree's): the OrientationBuilder
    // above reports a misleading orientation. Disabled when there's no key,
    // i.e. the slot is only reserving height and never visible.
    final scaffoldContext = scaffoldKey?.currentContext;

    return Center(
      child: TextButton(
        onPressed: scaffoldContext == null
            ? null
            : () => _showSecurePinRules(scaffoldContext, state),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              FlutterI18n.translate(context, "secure_pin.info_button"),
              style: context.yivi.pin.warningButton,
            ),
            const SizedBox(width: 2.0),
            Icon(Icons.info_outlined, color: context.yivi.brand.warning),
          ],
        ),
      ),
    );
  }
}
