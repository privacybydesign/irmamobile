part of 'yivi_pin_screen.dart';

class _UnsecurePinFullScreen extends StatelessWidget {
  final EnterPinState state;
  const _UnsecurePinFullScreen({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return YiviPinScaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'secure_pin.title',
        leadingAction: () => Navigator.of(context).pop(),
        hasBorder: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Text(
            FlutterI18n.translate(context, 'secure_pin.subtitle'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Divider(),
          ..._listBuilder(context, state)
        ],
      ),
    );
  }
}
