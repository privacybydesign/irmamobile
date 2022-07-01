import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:rxdart/subjects.dart';

import '../../util/safe_pin.dart';

const backgroundGrey = Color(0xFFE5E5E5);
const orange = Color(0xFFEBA73B);

typedef Pin = List<int>;
typedef PinStream = BehaviorSubject<Pin>;
typedef PinQuality = Set<UnsecurePinAttribute>;
typedef PinQualityStream = BehaviorSubject<PinQuality>;

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

class UnsecurePinWarningTextButton extends StatelessWidget {
  final PinQualityBloc bloc;
  final PinStream pinStream;
  const UnsecurePinWarningTextButton({Key? key, required this.pinStream, required this.bloc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PinQualityBloc, PinQuality>(
      bloc: bloc,
      builder: (context, rulesViolated) {
        if (rulesViolated.isNotEmpty) {
          return Center(
            child: TextButton(
              onPressed: () => _showSecurePinBottomSheet(context, rulesViolated),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    FlutterI18n.translate(context, 'secure_pin.info_button'),
                    style: const TextStyle(color: orange),
                  ),
                  const SizedBox(width: 2.0),
                  const Icon(
                    Icons.info_outlined,
                    color: orange,
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox(height: 16.0);
      },
    );
  }

  ListTile _ruleWidget(BuildContext context, Icon icon, String localeKey) => ListTile(
        leading: icon,
        horizontalTitleGap: 8.0,
        title: Text(
          FlutterI18n.translate(context, localeKey),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
        minVerticalPadding: 0.0,
        visualDensity: const VisualDensity(vertical: -4.0),
      );

  ListTile _requirementViolated(BuildContext context, String localeKey) => _ruleWidget(
        context,
        const Icon(Icons.check, color: Colors.green),
        localeKey,
      );

  ListTile _requirementFulfilled(BuildContext context, String localeKey) => _ruleWidget(
      context,
      const Icon(
        Icons.close,
        color: Colors.red,
      ),
      localeKey);

  ListTile _pinRule(BuildContext context, bool offendsRule, String localeKey) {
    if (offendsRule) {
      return _requirementViolated(context, localeKey);
    } else {
      return _requirementFulfilled(context, localeKey);
    }
  }

  void _showSecurePinBottomSheet(BuildContext context, PinQuality unsecurePinAttrs) {
    final rules = <Widget>[
      Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                FlutterI18n.translate(context, 'secure_pin.title'),
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_outlined,
                    semanticLabel: FlutterI18n.translate(context, 'accessibility.close'),
                    size: 16.0,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(
        height: 12,
      ),
      Text(
        FlutterI18n.translate(context, 'secure_pin.subtitle'),
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Divider(),
      _pinRule(context, unsecurePinAttrs.contains(UnsecurePinAttribute.containsThreeUnique),
          'secure_pin.rules.contains_3_unique'),
      const Divider(),
      _pinRule(context, unsecurePinAttrs.contains(UnsecurePinAttribute.mustNotAscNorDesc),
          'secure_pin.rules.must_not_asc_or_desc'),
      const Divider(),
      _pinRule(context, unsecurePinAttrs.contains(UnsecurePinAttribute.notAbcabNorAbcba),
          'secure_pin.rules.not_abcab_nor_abcba'),
    ];

    if (pinStream.value.length > 5) {
      rules
        ..add(const Divider())
        ..add(_pinRule(context, unsecurePinAttrs.contains(UnsecurePinAttribute.mustContainValidSubset),
            'secure_pin.rules.must_contain_valid_subset'));
    }

    // TODO yiviBottomSheetBuilder
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          decoration: const BoxDecoration(
            color: backgroundGrey,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: rules,
          ),
        ),
      ),
    );
  }
}
