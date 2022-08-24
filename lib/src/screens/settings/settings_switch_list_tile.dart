import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../theme/theme.dart';
import '../../util/haptics.dart';

class SettingsSwitchListTile extends StatelessWidget {
  final String titleTranslationKey;
  final String? subtitleTranslationKey;
  final Stream<bool> stream;
  final void Function(bool) onChanged;
  final IconData iconData;

  const SettingsSwitchListTile({
    Key? key,
    required this.titleTranslationKey,
    this.subtitleTranslationKey,
    required this.stream,
    required this.onChanged,
    required this.iconData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return StreamBuilder(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        return SwitchListTile.adaptive(
          title: Text(
            FlutterI18n.translate(context, titleTranslationKey),
            style: theme.textTheme.bodyText2,
          ),
          subtitle: subtitleTranslationKey != null
              ? Text(
                  FlutterI18n.translate(context, subtitleTranslationKey!),
                  style: theme.textTheme.caption!.copyWith(color: Colors.grey.shade500),
                )
              : null,
          activeColor: theme.themeData.colorScheme.secondary,
          value: snapshot.hasData && snapshot.data!,
          onChanged: onChanged.haptic,
          secondary: Icon(iconData, size: 30, color: theme.themeData.colorScheme.secondary),
        );
      },
    );
  }
}
