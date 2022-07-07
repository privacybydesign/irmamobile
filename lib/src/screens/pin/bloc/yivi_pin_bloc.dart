part of pin;

extension on PinQuality {
  void addSecurePinAttributeIfRuleFollowed(PinFn validator, SecurePinAttribute attr, Pin pin) {
    if (validator(pin)) {
      add(attr);
    }
  }

  void applyRules(Pin pin) {
    this
      ..addSecurePinAttributeIfRuleFollowed(
          pinMustContainAtLeastThreeUniqueNumbers, SecurePinAttribute.containsThreeUnique, pin)
      ..addSecurePinAttributeIfRuleFollowed(
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

void Function(String) pinStringToListConverter(PinStateBloc bloc) {
  return (String pin) => bloc.add(pin.split('').map((e) => int.parse(e)).toList());
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

  static final empty = PinState([], {});

  PinState(this.pin, this.attributes);
}

class PinStateBloc extends Bloc<Pin, PinState> {
  final int maxPinSize;
  static Pin _lastPin = PinState.empty.pin;

  PinStateBloc(this.maxPinSize) : super(PinState.empty);

  void update(int i) {
    if (_lastPin.isNotEmpty && i < 0) {
      add(_lastPin..removeLast());
    }

    if (_lastPin.length < maxPinSize && i >= 0) {
      add(_lastPin..add(i));
    }
  }

  @override
  Future<void> close() {
    _lastPin = PinState.empty.pin;
    return super.close();
  }

  @override
  Stream<PinState> mapEventToState(Pin pin) async* {
    final set = <SecurePinAttribute>{};
    _lastPin = pin;

    if (pin.length < 5) {
      yield PinState(pin, set);
    }

    if (pin.length == 5) {
      set.applyRules(pin);
    } else if (pin.length >= 5) {
      for (int i = 0; i < pin.length - 4; i++) {
        final sub = pin.sublist(i, i + 5);

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
