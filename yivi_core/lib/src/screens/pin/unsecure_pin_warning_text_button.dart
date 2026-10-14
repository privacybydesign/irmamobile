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
    final theme = IrmaTheme.of(context);

    // OrientationBuilder builds a widget tree that can depend on
    // the parent widget's orientation (distinct from the device orientation).
    // In this case, OrientationBuilder gives false results. Hence MediaQuery.
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (BuildContext context, _, _) =>
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
  }

  @override
  Widget build(BuildContext context) {
    // Use the scaffold's context (not this subtree's): the OrientationBuilder
    // above reports a misleading orientation. Disabled when there's no key,
    // i.e. the slot is only reserving height and never visible.
    final scaffoldContext = scaffoldKey?.currentContext;

    final palette = YiviPalette.of(context);
    return Center(
      child: Material(
        color: palette.warningSurface,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: scaffoldContext == null
              ? null
              : () => _showSecurePinRules(scaffoldContext, state),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: palette.warningText,
                  ),
                  Flexible(
                    child: Text(
                      FlutterI18n.translate(context, "secure_pin.info_button"),
                      style: palette
                          .body(13, weight: FontWeight.w600)
                          .copyWith(color: palette.warningText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
