import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/subjects.dart';

import '../../../util/secure_pin.dart';

typedef Pin = List<int>;
typedef PinStream = BehaviorSubject<Pin>;
typedef PinQuality = Set<SecurePinAttribute>;

extension on Set<SecurePinAttribute> {
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
  }
}

void Function(String) pinStringToListConverter(PinStream pinStream) {
  return (String pin) => pinStream.add(pin.split('').map((e) => int.parse(e)).toList());
}

enum SecurePinAttribute {
  atLeast5AtMost16,
  containsThreeUnique,
  mustNotAscNorDesc,
  notAbcabNorAbcba,
  mustContainValidSubset,
}

class PinQualityBloc extends Bloc<Pin, PinQuality> {
  final PinStream pinStream;
  late final StreamSubscription sub;

  PinQualityBloc(
    this.pinStream,
  ) : super({}) {
    sub = pinStream.listen((value) {
      add(value);
    });
  }

  @override
  Future<void> close() {
    sub.cancel();
    return super.close();
  }

  @override
  Stream<PinQuality> mapEventToState(Pin pin) async* {
    final set = <SecurePinAttribute>{};

    if (pin.length < 5) {
      yield set;
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

        if (kDebugMode) {
          print('$i: ${sub.join()}');
        }

        /// break when one subset is valid
        if (set.containsAll({
          SecurePinAttribute.containsThreeUnique,
          SecurePinAttribute.notAbcabNorAbcba,
          SecurePinAttribute.mustNotAscNorDesc
        })) {
          break;
        }
      }
    }

    if (kDebugMode) {
      print('$set');
    }

    yield set;
  }
}
