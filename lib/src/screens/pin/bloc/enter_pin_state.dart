part of pin;

typedef Pin = List<int>;
typedef UnmodifiablePin = Iterable<int>;

extension on PinQuality {
  void _addSecurePinAttributeIfRuleFollowed(bool Function(Pin) validator, SecurePinAttribute attr, Pin pin) {
    if (validator(pin)) {
      add(attr);
    }
  }

  void _applyRules(Pin pin) {
    this
      .._addSecurePinAttributeIfRuleFollowed(
          _pinMustContainAtLeastThreeUniqueNumbers, SecurePinAttribute.containsThreeUnique, pin)
      .._addSecurePinAttributeIfRuleFollowed(
          _pinMustNotBeMemberOfSeriesAscDesc, SecurePinAttribute.mustNotAscNorDesc, pin);

    if (_pinMustNotContainPatternAbcab(pin) && _pinMustNotContainPatternAbcba(pin)) {
      add(SecurePinAttribute.notAbcabNorAbcba);
    }
  }

  bool _hasCompleteSecurePinAttributes() => containsAll({
        SecurePinAttribute.containsThreeUnique,
        SecurePinAttribute.notAbcabNorAbcba,
        SecurePinAttribute.mustNotAscNorDesc
      });
}

enum SecurePinAttribute {
  containsThreeUnique,
  mustNotAscNorDesc,
  notAbcabNorAbcba,
  mustContainValidSubset,
}

@immutable
class EnterPinState {
  final UnmodifiablePin pin;
  final PinQuality attributes;
  final bool goodEnough;
  final String _string;

  EnterPinState(Pin p, PinQuality attrs, this.goodEnough)
      : pin = List.unmodifiable(p),
        attributes = PinQuality.unmodifiable(List<SecurePinAttribute>.unmodifiable(attrs.toList())),
        _string = p.join();

  EnterPinState.empty()
      : pin = List.unmodifiable([]),
        attributes = PinQuality.unmodifiable(List<SecurePinAttribute>.unmodifiable([])),
        _string = '',
        goodEnough = false;

  @override
  String toString() {
    return _string;
  }
}

EnterPinState _pinStateFactory(Pin pin) {
  final set = <SecurePinAttribute>{};
  var goodEnough = false;

  if (pin.length < shortPinSize) {
    return EnterPinState(pin, set, goodEnough);
  }

  if (pin.length == shortPinSize) {
    set._applyRules(pin);
    goodEnough = set._hasCompleteSecurePinAttributes();
  } else if (pin.length >= shortPinSize) {
    for (int i = 0; i < pin.length - 4; i++) {
      final sub = pin.sublist(i, i + shortPinSize);

      // report the last pin secure attributes
      set
        ..clear()
        .._applyRules(sub);

      // break when one subset is valid
      goodEnough = set._hasCompleteSecurePinAttributes();
      if (goodEnough) {
        break;
      }
    }
  }

  return EnterPinState(pin, set, goodEnough);
}

class EnterPinStateBloc extends Bloc<int, EnterPinState> {
  final int maxPinSize;
  EnterPinStateBloc(this.maxPinSize) : super(EnterPinState.empty());

  @override
  Stream<EnterPinState> mapEventToState(int event) async* {
    Pin pin = Pin.from(state.pin);
    if (event >= 0 && event < 10) {
      pin.add(event);
    } else {
      pin.removeLast();
    }

    yield _pinStateFactory(pin);
  }
}

@visibleForTesting
class TestEnterPinStateBloc extends Bloc<Pin, EnterPinState> {
  final int maxPinSize;

  TestEnterPinStateBloc(this.maxPinSize) : super(EnterPinState.empty());

  @override
  void add(Pin event) {
    super.add(event.length > maxPinSize ? event.sublist(0, maxPinSize) : event);
  }

  @override
  Stream<EnterPinState> mapEventToState(Pin event) async* {
    yield _pinStateFactory(event);
  }
}
