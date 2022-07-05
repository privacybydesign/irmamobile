part of pin;

class _VisiblePinIndicator extends StatelessWidget {
  final int maxPinSize;
  final PinStream pinStream;

  const _VisiblePinIndicator({
    Key? key,
    required this.maxPinSize,
    required this.pinStream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Pin>(
      initialData: const [],
      stream: pinStream,
      builder: (context, snapshot) => _visiblePin(context, maxPinSize, snapshot.hasData ? snapshot.data ?? [] : []),
    );
  }

  Widget _visiblePin(BuildContext context, int maxPinSize, Pin data) {
    final theme = IrmaTheme.of(context);

    final style = maxPinSize != _minPinSize
        ? theme.textTheme.headline5?.copyWith(
            color: theme.pinIndicatorDarkBlue,
          )
        : theme.textTheme.headline2?.copyWith(
            color: theme.pinIndicatorDarkBlue,
          );

    return Container(
      decoration: BoxDecoration(
        border: maxPinSize == _minPinSize
            ? null
            : Border(
                bottom: BorderSide(color: theme.darkPurple),
              ),
      ),
      child: SizedBox(
        width: maxPinSize == _minPinSize ? 100 : 230,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            data.length,
            (i) => Text(
              '${data[i]}',
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}
