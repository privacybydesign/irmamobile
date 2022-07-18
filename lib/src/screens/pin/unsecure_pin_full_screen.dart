part of pin;

class _UnsecurePinFullScreen extends StatelessWidget {
  final EnterPinState state;
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
