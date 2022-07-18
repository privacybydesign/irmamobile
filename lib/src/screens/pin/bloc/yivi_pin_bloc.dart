part of pin;

extension on PinQuality {
  void _addSecurePinAttributeIfRuleFollowed(PinFn validator, SecurePinAttribute attr, Pin pin) {
    if (validator(pin)) {
      add(attr);
    }
  }

  void applyRules(Pin pin) {
    this
      .._addSecurePinAttributeIfRuleFollowed(
          pinMustContainAtLeastThreeUniqueNumbers, SecurePinAttribute.containsThreeUnique, pin)
      .._addSecurePinAttributeIfRuleFollowed(
          pinMustNotBeMemberOfSeriesAscDesc, SecurePinAttribute.mustNotAscNorDesc, pin);

    if (pinMustNotContainPatternAbcab(pin) && pinMustNotContainPatternAbcba(pin)) {
      add(SecurePinAttribute.notAbcabNorAbcba);
    }

    if (containsAll({
      SecurePinAttribute.containsThreeUnique,
      SecurePinAttribute.notAbcabNorAbcba,
      SecurePinAttribute.mustNotAscNorDesc
    })) {
      this
        ..clear()
        ..add(SecurePinAttribute.goodEnough);
    }
  }
}

enum SecurePinAttribute {
  atLeast5AtMost16,
  containsThreeUnique,
  mustNotAscNorDesc,
  notAbcabNorAbcba,
  mustContainValidSubset,
  goodEnough,
}

class PinState {
  final Pin pin;
  final PinQuality attributes;

  static final empty = PinState(const [], const {});

  PinState(this.pin, this.attributes);
}

class PinStateBloc extends Bloc<Pin, PinState> {
  final int maxPinSize;
  Pin _lastPin = PinState.empty.pin;

  PinStateBloc(this.maxPinSize) : super(PinState.empty);

  @override
  void add(Pin p) {
    super.add(p.length > maxPinSize ? p.sublist(0, maxPinSize) : p);
  }

  /// For some reason the stream survives widget changes
  /// across instances of this Bloc
  /// via an unconst PinState.empty, when yielding
  /// so now we const PinState.empty and also
  /// deep-copy clone the intermediate state
  void update(int i) {
    if (_lastPin.isNotEmpty && i < 0) {
      add([..._lastPin]..removeLast());
    }

    if (_lastPin.length < maxPinSize && i >= 0) {
      add([..._lastPin]..add(i));
    }
  }

  @override
  Stream<PinState> mapEventToState(Pin pin) async* {
    final set = <SecurePinAttribute>{};
    _lastPin = pin;

    if (pin.length < shortPinSize) {
      yield PinState(pin, set);
    }

    if (pin.length == shortPinSize) {
      set.applyRules(pin);
    } else if (pin.length >= shortPinSize) {
      for (int i = 0; i < pin.length - 4; i++) {
        final sub = pin.sublist(i, i + shortPinSize);

        /// report the last pin secure attributes
        set
          ..clear()
          ..applyRules(sub);

        /// break when one subset is valid
        if (set.contains(SecurePinAttribute.goodEnough)) {
          break;
        }
      }
    }

    yield PinState(pin, set);
  }
}
