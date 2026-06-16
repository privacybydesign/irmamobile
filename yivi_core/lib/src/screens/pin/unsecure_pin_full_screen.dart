part of "yivi_pin_screen.dart";

class _UnsecurePinFullScreen extends StatelessWidget {
  final EnterPinState state;
  const _UnsecurePinFullScreen({required this.state});

  @override
  Widget build(BuildContext context) {
    return YiviPinScaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: "secure_pin.title",
        hasBorder: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Text(
            FlutterI18n.translate(context, "secure_pin.subtitle"),
            style: context.yivi.pin.warningHeading,
          ),
          const Divider(),
          ..._listBuilder(context, state),
        ],
      ),
    );
  }
}
