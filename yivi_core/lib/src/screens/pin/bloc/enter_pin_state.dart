part of "../yivi_pin_screen.dart";

typedef Pin = List<int>;
typedef UnmodifiablePin = Iterable<int>;

extension on PinQuality {
  void _addSecurePinAttributeIfRuleFollowed(
    bool Function(Pin) validator,
    SecurePinAttribute attr,
    Pin pin,
  ) {
    if (validator(pin)) {
      add(attr);
    }
  }

  void _applyRules(Pin pin) {
    this
      .._addSecurePinAttributeIfRuleFollowed(
        _pinMustContainAtLeastThreeUniqueNumbers,
        SecurePinAttribute.containsThreeUnique,
        pin,
      )
      .._addSecurePinAttributeIfRuleFollowed(
        _pinMustNotBeMemberOfSeriesAscDesc,
        SecurePinAttribute.mustNotAscNorDesc,
        pin,
      );

    if (_pinMustNotContainPatternAbcab(pin) &&
        _pinMustNotContainPatternAbcba(pin)) {
      add(SecurePinAttribute.notAbcabNorAbcba);
    }
  }

  bool _hasCompleteSecurePinAttributes() => containsAll({
    SecurePinAttribute.containsThreeUnique,
    SecurePinAttribute.notAbcabNorAbcba,
    SecurePinAttribute.mustNotAscNorDesc,
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

  EnterPinState._(Pin p, PinQuality attrs, this.goodEnough)
    : pin = List.unmodifiable(p),
      attributes = PinQuality.unmodifiable(
        List<SecurePinAttribute>.unmodifiable(attrs.toList()),
      ),
      _string = p.join();

  EnterPinState.empty()
    : pin = List.unmodifiable(const []),
      attributes = PinQuality.unmodifiable(
        List<SecurePinAttribute>.unmodifiable(const []),
      ),
      _string = "",
      goodEnough = false;

  @override
  String toString() {
    return _string;
  }

  factory EnterPinState.createFrom({required Pin pin}) {
    final set = <SecurePinAttribute>{};
    var goodEnough = false;

    if (pin.length < shortPinSize) {
      return EnterPinState._(pin, set, goodEnough);
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

    return EnterPinState._(pin, set, goodEnough);
  }
}

final enterPinProvider =
    NotifierProvider.autoDispose<EnterPinNotifier, EnterPinState>(
      EnterPinNotifier.new,
    );

class EnterPinNotifier extends Notifier<EnterPinState> {
  int _maxPinSize = shortPinSize;

  @override
  EnterPinState build() => EnterPinState.empty();

  int get maxPinSize => _maxPinSize;

  void configure(int maxPinSize) {
    if (_maxPinSize != maxPinSize) {
      _maxPinSize = maxPinSize;
      state = EnterPinState.empty();
    }
  }

  void enterNumber(int number) {
    if (number >= 0 && number < 10 && state.pin.length < _maxPinSize) {
      final pin = Pin.from(state.pin)..add(number);
      state = EnterPinState.createFrom(pin: pin);
    } else if (number.isNegative && state.pin.isNotEmpty) {
      final pin = Pin.from(state.pin)..removeLast();
      state = EnterPinState.createFrom(pin: pin);
    }
  }

  void clear() => state = EnterPinState.empty();

  @visibleForTesting
  void setPin(Pin pin) {
    final clampedPin = pin.length > _maxPinSize
        ? pin.sublist(0, _maxPinSize)
        : pin;
    state = EnterPinState.createFrom(pin: clampedPin);
  }
}
