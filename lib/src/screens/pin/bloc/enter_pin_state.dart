part of pin;

extension on PinQuality {
  void _addSecurePinAttributeIfRuleFollowed(PinCallback validator, SecurePinAttribute attr, Pin pin) {
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
  final Pin pin;
  final PinQuality attributes;
  final bool goodEnough;
  final String _string;

  static final empty = EnterPinState(const [], const {}, false);

  EnterPinState(this.pin, this.attributes, this.goodEnough) : _string = pin.join();

  @override
  String toString() {
    return _string;
  }
}

class EnterPinStateBloc extends Bloc<Pin, EnterPinState> {
  final int maxPinSize;

  EnterPinStateBloc(this.maxPinSize) : super(EnterPinState.empty);

  @override
  void add(Pin p) {
    super.add(p.length > maxPinSize ? p.sublist(0, maxPinSize) : p);
  }

  void update(int i) {
    Pin previousPin = state.pin;
    if (previousPin.isNotEmpty && i < 0) {
      add([...previousPin]..removeLast());
    }

    if (previousPin.length < maxPinSize && i >= 0) {
      add([...previousPin, i]);
    }
  }

  @override
  Stream<EnterPinState> mapEventToState(Pin pin) async* {
    final set = <SecurePinAttribute>{};
    var goodEnough = false;

    if (pin.length < shortPinSize) {
      yield EnterPinState(pin, set, goodEnough);
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

    yield EnterPinState(pin, set, goodEnough);
  }
}
