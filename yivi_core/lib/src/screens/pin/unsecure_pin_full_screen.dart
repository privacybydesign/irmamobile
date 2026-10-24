part of "yivi_pin_screen.dart";

class _UnsecurePinFullScreen extends StatelessWidget {
  final EnterPinState state;
  const _UnsecurePinFullScreen({required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return YiviPinScaffold(
      appBar: IrmaAppBar(titleTranslationKey: "secure_pin.title"),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Text(
            FlutterI18n.translate(context, "secure_pin.subtitle"),
            style: palette.body(16, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._listBuilder(context, state),
        ],
      ),
    );
  }
}
