part of pin;

List<Widget> _listBuilder(BuildContext context, PinState state) {
  final attributes = state.attributes;
  final tiles = [
    _UnsecurePinDescriptionTile(
      followsRule: attributes.contains(SecurePinAttribute.containsThreeUnique),
      descriptionKey: 'secure_pin.rules.contains_3_unique',
    ),
    _UnsecurePinDescriptionTile(
      followsRule: attributes.contains(SecurePinAttribute.mustNotAscNorDesc),
      descriptionKey: 'secure_pin.rules.must_not_asc_or_desc',
    ),
    _UnsecurePinDescriptionTile(
      followsRule: attributes.contains(SecurePinAttribute.notAbcabNorAbcba),
      descriptionKey: 'secure_pin.rules.not_abcab_nor_abcba',
    ),
    if (state.pin.length > shortPinSize)
      _UnsecurePinDescriptionTile(
        followsRule: attributes.contains(SecurePinAttribute.mustContainValidSubset),
        descriptionKey: 'secure_pin.rules.must_contain_valid_subset',
      )
  ];

  return ListTile.divideTiles(
    context: context,
    tiles: tiles,
  ).toList();
}

class UnsecurePinWarningTextButton extends StatelessWidget {
  final PinStateBloc bloc;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const UnsecurePinWarningTextButton({Key? key, required this.scaffoldKey, required this.bloc}) : super(key: key);

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
            if (state.pin.length >= shortPinSize) {
              if (!state.attributes.contains(SecurePinAttribute.goodEnough)) {
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
              }
            }
            return const SizedBox(height: 0.0); // placeholder
          },
        );
      },
    );
  }
}

class _UnsecurePinDescriptionTile extends StatelessWidget {
  final bool followsRule;
  final String descriptionKey;
  const _UnsecurePinDescriptionTile({Key? key, required this.followsRule, required this.descriptionKey})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return ListTile(
      leading: Icon(
        followsRule ? Icons.check : Icons.close,
        color: followsRule ? Colors.green : Colors.red,
      ),
      horizontalTitleGap: 8.0,
      title: Text(
        FlutterI18n.translate(context, descriptionKey),
        style: theme.textTheme.bodyText1?.copyWith(fontWeight: FontWeight.w400),
      ),
      minVerticalPadding: 0.0,
      visualDensity: const VisualDensity(vertical: -4.0),
    );
  }
}

class _UnsecurePinFullScreen extends StatelessWidget {
  final PinState state;
  const _UnsecurePinFullScreen({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return YiviPinScaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'secure_pin.title',
        leadingAction: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: _listBuilder(context, state),
      ),
    );
  }
}
