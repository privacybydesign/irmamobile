part of 'yivi_pin_screen.dart';

class _NumberPadIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback callback;
  const _NumberPadIcon({required this.icon, required this.callback});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: callback.haptic,
        child: IgnorePointer(
          child: FractionallySizedBox(
            heightFactor: .5,
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: Container(
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: theme.secondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
