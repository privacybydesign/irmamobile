import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/subjects.dart';

import '../../../util/secure_pin.dart';

typedef Pin = List<int>;
typedef PinStream = BehaviorSubject<Pin>;
typedef PinQuality = Set<UnsecurePinAttribute>;

void Function(String) pinStringToListConverter(PinStream pinStream) {
  return (String pin) => pinStream.add(pin.split('').map((e) => int.parse(e)).toList());
}

enum UnsecurePinAttribute {
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
    final set = <UnsecurePinAttribute>{};

    if (pin.length < 5) {
      yield set;
    }

    if (pinSizeMustBeAtLeast5AtMost16(pin)) {
      set.add(UnsecurePinAttribute.atLeast5AtMost16);
    } else if (pinMustContainAtLeastThreeUniqueNumbers(pin)) {
      set.add(UnsecurePinAttribute.containsThreeUnique);
    } else if (pinMustNotBeMemberOfSeriesAscDesc(pin)) {
      set.add(UnsecurePinAttribute.mustNotAscNorDesc);
    } else if (pinMustNotContainPatternAbcab(pin) && pinMustNotContainPatternAbcba(pin)) {
      set.add(UnsecurePinAttribute.notAbcabNorAbcba);
    }

    if (pin.length > 5) {
      if (pinMustContainASublistOfSize5ThatCompliesToAllRules(pin)) {
        set.add(UnsecurePinAttribute.mustContainValidSubset);
      }
    }

    yield set;
  }
}
