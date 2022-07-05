part of pin;

class _PinVisibilityBloc extends Bloc<bool, bool> {
  _PinVisibilityBloc() : super(false);

  @override
  Stream<bool> mapEventToState(bool event) async* {
    yield event;
  }
}
