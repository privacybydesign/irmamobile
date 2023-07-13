import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_icon_button.dart';
import 'notification_indicator.dart';

class NotificationBell extends StatelessWidget {
  final Function() onTap;

  const NotificationBell({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.all(theme.smallSpacing),
      child: Stack(
        children: [
          IrmaIconButton(
            padding: EdgeInsets.zero,
            size: 32,
            icon: Icons.notifications_outlined,
            onTap: onTap,
          ),
          Positioned(
            top: 5,
            right: 5,
            child: NotificationIndicator(),
          )
        ],
      ),
    );
  }
}
