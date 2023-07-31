import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_icon_button.dart';
import 'notification_indicator.dart';

class NotificationBell extends StatelessWidget {
  final Function() onTap;
  final bool showIndicator;

  const NotificationBell({
    Key? key,
    required this.onTap,
    this.showIndicator = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.all(theme.smallSpacing),
      child: Semantics(
        button: true,
        label: FlutterI18n.translate(
          context,
          'notifications.bell.${showIndicator ? 'new_notifications' : 'no_new_notifications'}',
        ),
        child: Stack(
          children: [
            IrmaIconButton(
              padding: EdgeInsets.zero,
              size: 32,
              icon: Icons.notifications_outlined,
              onTap: onTap,
            ),
            if (showIndicator)
              Positioned(
                top: 5,
                right: 5,
                child: NotificationIndicator(),
              )
          ],
        ),
      ),
    );
  }
}
