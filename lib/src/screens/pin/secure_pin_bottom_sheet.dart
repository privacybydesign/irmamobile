import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

import '../../widgets/yivi_bottom_sheet.dart';
import 'bloc/pin_quality.dart';

class UnsecurePinWarningTextButton extends StatelessWidget {
  final PinQualityBloc bloc;
  final PinStream pinStream;
  const UnsecurePinWarningTextButton({Key? key, required this.pinStream, required this.bloc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return BlocBuilder<PinQualityBloc, PinQuality>(
      bloc: bloc,
      builder: (context, rulesViolated) {
        if (rulesViolated.isNotEmpty) {
          return Center(
            child: TextButton(
              onPressed: () => _showSecurePinBottomSheet(context, theme, rulesViolated),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    FlutterI18n.translate(context, 'secure_pin.info_button'),
                    style: theme.textTheme.caption?.copyWith(color: theme.securePinOrange, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 2.0),
                  Icon(
                    Icons.info_outlined,
                    color: theme.securePinOrange,
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

  ListTile _ruleWidget(BuildContext context, IrmaThemeData theme, Icon icon, String localeKey) => ListTile(
        leading: icon,
        horizontalTitleGap: 8.0,
        title: Text(
          FlutterI18n.translate(context, localeKey),
          style: theme.textTheme.bodyText1?.copyWith(fontWeight: FontWeight.w400),
        ),
        minVerticalPadding: 0.0,
        visualDensity: const VisualDensity(vertical: -4.0),
      );

  ListTile _pinRule(BuildContext context, IrmaThemeData theme, bool followsRule, String localeKey) => _ruleWidget(
        context,
        theme,
        Icon(
          followsRule ? Icons.check : Icons.close,
          color: followsRule ? Colors.green : Colors.red,
        ),
        localeKey,
      );

  void _showSecurePinBottomSheet(BuildContext context, IrmaThemeData theme, PinQuality unsecurePinAttrs) {
    final rules = <Widget>[
      Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                FlutterI18n.translate(context, 'secure_pin.title'),
                style: theme.textTheme.headline3?.copyWith(
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
        style: theme.textTheme.headline5?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const Divider(),
      _pinRule(context, theme, unsecurePinAttrs.contains(UnsecurePinAttribute.containsThreeUnique),
          'secure_pin.rules.contains_3_unique'),
      const Divider(),
      _pinRule(context, theme, unsecurePinAttrs.contains(UnsecurePinAttribute.mustNotAscNorDesc),
          'secure_pin.rules.must_not_asc_or_desc'),
      const Divider(),
      _pinRule(context, theme, unsecurePinAttrs.contains(UnsecurePinAttribute.notAbcabNorAbcba),
          'secure_pin.rules.not_abcab_nor_abcba'),
    ];

    if (pinStream.value.length > 5) {
      rules
        ..add(const Divider())
        ..add(_pinRule(context, theme, unsecurePinAttrs.contains(UnsecurePinAttribute.mustContainValidSubset),
            'secure_pin.rules.must_contain_valid_subset'));
    }

    showYiviBottomSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: rules,
      ),
    );
  }
}
