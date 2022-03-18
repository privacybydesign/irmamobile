// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_message.dart';

void startBottombarMessages(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) {
      return BottomBar();
    }),
  );
}

class BottomBar extends StatefulWidget {
  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  bool showTooltip;

  @override
  void initState() {
    super.initState();
    showTooltip = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              _buildMessageExample(
                context,
                "Message with `valid` style",
                IrmaMessage(
                  "help.about_irma",
                  "app_tab.slogan",
                  type: IrmaMessageType.valid,
                ),
              ),
              _buildMessageExample(
                context,
                "Message with `invalid` style",
                IrmaMessage(
                  "help.about_irma",
                  "app_tab.slogan",
                  type: IrmaMessageType.invalid,
                ),
              ),
              _buildMessageExample(
                context,
                "Message with `alert` style",
                IrmaMessage(
                  "help.about_irma",
                  "app_tab.slogan",
                  type: IrmaMessageType.alert,
                ),
              ),
              _buildMessageExample(
                context,
                "Message with `info` style",
                IrmaMessage(
                  "help.about_irma",
                  "app_tab.slogan",
                  type: IrmaMessageType.info,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'settings.advanced.delete_confirm',
        onPrimaryPressed: () => debugPrint("pressed confirm"),
        onPrimaryDisabledPressed: () => debugPrint("pressed disabled confirm"),
        secondaryButtonLabel: 'settings.advanced.delete_deny',
        onSecondaryPressed: () {
          setState(() {
            showTooltip = !showTooltip;
          });
        },
        showTooltipOnPrimary: showTooltip,
        toolTipLabel: 'settings.advanced.delete_deny',
      ),
    );
  }

  Widget _buildMessageExample(BuildContext context, String name, Widget button) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: <Widget>[
          button,
          const SizedBox(height: 8.0),
          Text(name, style: IrmaTheme.of(context).textTheme.caption.copyWith(color: IrmaTheme.of(context).grayscale80)),
        ],
      ),
    );
  }
}
