import 'package:flutter/material.dart';

import 'notification_indicator.dart';

class NotificationBell extends StatelessWidget {
  final Function() onTap;
  final bool showIndicator;
  final bool outlined;
  final Color? color;

  const NotificationBell({
    super.key,
    required this.onTap,
    this.showIndicator = false,
    this.outlined = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(outlined ? Icons.notifications_outlined : Icons.notifications, size: 28, color: color),
        if (showIndicator) Positioned(top: 5, right: 5, child: NotificationIndicator()),
      ],
    );
  }
}
