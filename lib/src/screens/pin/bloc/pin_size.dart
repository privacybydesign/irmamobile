part of pin;

class _PinSizeBloc extends Bloc<Pin, int> {
  final PinStream pinStream;

  _PinSizeBloc(this.pinStream) : super(0) {
    pinStream.listen((pin) => add(pin));
  }

  @override
  Stream<int> mapEventToState(Pin pin) async* {
    yield pin.length;
  }
}
