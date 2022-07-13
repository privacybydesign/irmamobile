part of pin;

class PinVisibilityBloc extends Bloc<bool, bool> {
  PinVisibilityBloc() : super(false);

  @override
  Stream<bool> mapEventToState(bool event) async* {
    yield event;
  }
}
