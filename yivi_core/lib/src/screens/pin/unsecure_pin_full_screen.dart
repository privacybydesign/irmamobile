part of "yivi_pin_screen.dart";

class _UnsecurePinFullScreen extends StatelessWidget {
  final EnterPinState state;
  const _UnsecurePinFullScreen({required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return YiviPinScaffold(
      appBar: YiviAppBar(titleTranslationKey: "secure_pin.title"),
      body: ListView(
        padding: const EdgeInsets.all(YiviSpace.x8),
        children: [
          Text(
            context.tr("secure_pin.subtitle"),
            style: palette.body(16, weight: FontWeight.w600),
          ),
          const SizedBox(height: YiviSpace.x8),
          ..._listBuilder(context, state),
        ],
      ),
    );
  }
}
