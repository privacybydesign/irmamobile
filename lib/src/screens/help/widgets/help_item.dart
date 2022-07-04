import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/widgets/collapsible.dart';

class HelpItem extends StatefulWidget {
  final GlobalKey parentKey;
  final ScrollController parentScrollController;

  final String headerTranslationKey;
  final Widget body;

  const HelpItem(
      {required this.parentKey,
      required this.parentScrollController,
      required this.headerTranslationKey,
      required this.body});

  @override
  _HelpItemState createState() => _HelpItemState();
}

class _HelpItemState extends State<HelpItem> with TickerProviderStateMixin {
  final GlobalKey _collapseKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // TODO: remove key
    return Collapsible(
      key: _collapseKey,
      header: FlutterI18n.translate(context, widget.headerTranslationKey),
      parentScrollController: widget.parentScrollController,
      content: widget.body,
    );
  }
}
