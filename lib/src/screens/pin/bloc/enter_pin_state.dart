part of '../yivi_pin_screen.dart';

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
        _pinMustContainAtLeastThreeUniqueNumbers,
        SecurePinAttribute.containsThreeUnique,
        pin,
      )
      .._addSecurePinAttributeIfRuleFollowed(
        _pinMustNotBeMemberOfSeriesAscDesc,
        SecurePinAttribute.mustNotAscNorDesc,
        pin,
      );

    if (_pinMustNotContainPatternAbcab(pin) && _pinMustNotContainPatternAbcba(pin)) {
      add(SecurePinAttribute.notAbcabNorAbcba);
    }
  }

  bool _hasCompleteSecurePinAttributes() => containsAll({
    SecurePinAttribute.containsThreeUnique,
    SecurePinAttribute.notAbcabNorAbcba,
    SecurePinAttribute.mustNotAscNorDesc,
  });
}

enum SecurePinAttribute { containsThreeUnique, mustNotAscNorDesc, notAbcabNorAbcba, mustContainValidSubset }

@immutable
class EnterPinState {
  final UnmodifiablePin pin;
  final PinQuality attributes;
  final bool goodEnough;
  final String _string;

  EnterPinState._(Pin p, PinQuality attrs, this.goodEnough)
    : pin = List.unmodifiable(p),
      attributes = PinQuality.unmodifiable(List<SecurePinAttribute>.unmodifiable(attrs.toList())),
      _string = p.join();

  EnterPinState.empty()
    : pin = List.unmodifiable(const []),
      attributes = PinQuality.unmodifiable(List<SecurePinAttribute>.unmodifiable(const [])),
      _string = '',
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

class EnterPinStateBloc extends Bloc<int, EnterPinState> {
  final int maxPinSize;
  EnterPinStateBloc(this.maxPinSize) : super(EnterPinState.empty());

  @override
  Stream<EnterPinState> mapEventToState(int event) async* {
    Pin pin = Pin.from(state.pin);

    if (event >= 0 && event < 10 && state.pin.length < maxPinSize) {
      pin.add(event);
    } else if (event.isNegative && state.pin.isNotEmpty) {
      pin.removeLast();
    }

    yield EnterPinState.createFrom(pin: pin);
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
    yield EnterPinState.createFrom(pin: event);
  }
}
