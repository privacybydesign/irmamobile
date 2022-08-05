part of pin;

class _NumberPadIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback callback;
  const _NumberPadIcon({Key? key, required this.icon, required this.callback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: constraints,
        child: ClipPath(
          clipper: _PerfectCircleClip(),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => callback(),
              child: IgnorePointer(
                child: FractionallySizedBox(
                  // alignment: Alignment.topCenter,
                  heightFactor: .5,
                  child: FittedBox(
                    // fit: BoxFit.scaleDown,
                    fit: BoxFit.fitHeight,
                    child: Container(
                      // color: Colors.transparent,
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
          ),
        ),
      ),
    );
  }
}
