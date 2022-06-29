import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../util/safe_pin.dart';

const backgroundGrey = Color(0xFFE5E5E5);
const orange = Color(0xFFEBA73B);

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

ListTile _offendingRule(BuildContext context, String localeKey) => _ruleWidget(
      context,
      const Icon(Icons.check, color: Colors.green),
      localeKey,
    );

ListTile _abidingRule(BuildContext context, String localeKey) => _ruleWidget(
    context,
    const Icon(
      Icons.close,
      color: Colors.red,
    ),
    localeKey);

ListTile _pinRule(BuildContext context, bool offendsRule, String localeKey) {
  if (offendsRule) {
    return _offendingRule(context, localeKey);
  } else {
    return _abidingRule(context, localeKey);
  }
}

Widget infoButton(BuildContext context, Stream<List<int>> pinStream) => StreamBuilder<List<int>>(
    initialData: const [],
    stream: pinStream,
    builder: (context, snapshot) {
      if (snapshot.hasData && snapshot.data!.length >= 5 && !pinRules.every((r) => r(snapshot.data!))) {
        return Center(
          child: TextButton(
            onPressed: () => _showSecurePinBottomSheet(context, snapshot.data!),
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
    });

void _showSecurePinBottomSheet(BuildContext context, List<int> pin) {
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
    _pinRule(context, pinSizeMustBeAtLeast5AtMost13(pin), 'secure_pin.rules.atleast5atmost13'),
    const Divider(),
    _pinRule(context, pinMustContainAtLeastThreeUniqueNumbers(pin), 'secure_pin.rules.contains3unique'),
    const Divider(),
    _pinRule(context, pinMustNotBeMemberOfSeriesAscDesc(pin), 'secure_pin.rules.mustNotAscDesc'),
    const Divider(),
    _pinRule(context, pinMustNotContainPatternAbcab(pin) && pinMustNotContainPatternAbcba(pin),
        'secure_pin.rules.notAbcabNorAbcba')
  ];

  if (pin.length > 5) {
    rules
      ..add(const Divider())
      ..add(_pinRule(context, pinMustContainASublistOfSize5ThatCompliesToAllRules(pin),
          'secure_pin.rules.pinSizeGt5MustContainValidSubset'));
  }

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
