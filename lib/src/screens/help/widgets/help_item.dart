import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../widgets/collapsible.dart';

class HelpItem extends StatelessWidget {
  final ScrollController parentScrollController;

  final String headerTranslationKey;
  final Widget body;

  const HelpItem({required this.parentScrollController, required this.headerTranslationKey, required this.body});

  @override
  Widget build(BuildContext context) => Collapsible(
    header: FlutterI18n.translate(context, headerTranslationKey),
    parentScrollController: parentScrollController,
    content: body,
  );
}
