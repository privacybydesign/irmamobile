part of 'yivi_pin_screen.dart';

class _UnsecurePinWarningTextButton extends StatelessWidget {
  final EnterPinStateBloc bloc;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final BuildContext context;

  _UnsecurePinWarningTextButton({required this.scaffoldKey, required this.bloc})
      : context = scaffoldKey.currentContext!;

  void _showSecurePinRules(EnterPinState state) {
    final theme = IrmaTheme.of(context);
    final rules = <Widget>[
      Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                FlutterI18n.translate(context, 'secure_pin.title'),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: const SizedBox.square(dimension: 32),
                ),
                IconButton(
                  alignment: Alignment.center,
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_outlined,
                    semanticLabel: FlutterI18n.translate(context, 'accessibility.close'),
                    size: 18,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      SizedBox(height: theme.screenPadding),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          FlutterI18n.translate(context, 'secure_pin.subtitle'),
          style: theme.textTheme.bodyMedium,
        ),
      ),
      SizedBox(height: theme.screenPadding),
      ..._listBuilder(context, state),
      const SizedBox(height: 32),
    ];

    // OrientationBuilder builds a widget tree that can depend on
    // the parent widget's orientation (distinct from the device orientation).
    // In this case, OrientationBuilder gives false results. Hence MediaQuery.
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (BuildContext context, _, __) => _UnsecurePinFullScreen(state: state),
        ),
      );
    } else {
      showYiviBottomSheet(
        context: context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: rules,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return BlocBuilder<EnterPinStateBloc, EnterPinState>(
      bloc: bloc,
      builder: (context, state) {
        return Center(
          child: TextButton(
            onPressed: () => _showSecurePinRules(state),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  FlutterI18n.translate(context, 'secure_pin.info_button'),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.warning, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 2.0),
                Icon(
                  Icons.info_outlined,
                  color: theme.warning,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
