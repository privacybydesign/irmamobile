part of pin;

class _UnsecurePinWarningTextButton extends StatelessWidget {
  final PinStateBloc bloc;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _UnsecurePinWarningTextButton({Key? key, required this.scaffoldKey, required this.bloc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final shortSide = shortestSide(context);

    void showSecurePinRules(PinState state, Orientation orientation) {
      final rules = <Widget>[
        Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  FlutterI18n.translate(context, 'secure_pin.title'),
                  style: theme.textTheme.headline3?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_outlined,
                      semanticLabel: FlutterI18n.translate(context, 'accessibility.close'),
                      size: 16.0,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Text(
          FlutterI18n.translate(context, 'secure_pin.subtitle'),
          style: theme.textTheme.headline5?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Divider(),
        ..._listBuilder(context, state),
      ];

      /// The bottom sheet is a cute idea
      /// but at <350 smallest edge, on landscape
      /// the overflows are inevitable
      /// In this case, go full screen
      if (shortSide < 350 && Orientation.landscape == orientation) {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (BuildContext context, _, __) => _UnsecurePinFullScreen(state: state),
          ),
        );
      } else {
        showYiviBottomSheet(
          context: scaffoldKey.currentContext!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: rules,
          ),
        );
      }
    }

    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return BlocBuilder<PinStateBloc, PinState>(
          bloc: bloc,
          builder: (context, state) {
            return Center(
              child: TextButton(
                onPressed: () => showSecurePinRules(state, orientation),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      FlutterI18n.translate(context, 'secure_pin.info_button'),
                      style: theme.textTheme.caption?.copyWith(color: theme.warning, fontWeight: FontWeight.w700),
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
      },
    );
  }
}
