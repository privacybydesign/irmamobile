import 'package:flutter/material.dart';

import '../../../../models/irma_configuration.dart';
import '../../../../widgets/active_indicator.dart';

class SchemeManagerTile extends StatelessWidget {
  final SchemeManager schemeManager;
  final bool? isActive;
  final Function()? onTap;

  const SchemeManagerTile({
    required this.schemeManager,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(schemeManager.id),
      trailing: isActive != null ? ActiveIndicator(isActive!) : null,
      onTap: onTap,
    );
  }
}
