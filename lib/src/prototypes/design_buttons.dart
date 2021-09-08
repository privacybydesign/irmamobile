// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_outlined_button.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

void startDesignButtons(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) {
      return DesignButtons();
    }),
  );
}

class DesignButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IrmaAppBar(
        title: Text("Buttons"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              Text("Contained", style: IrmaTheme.of(context).textTheme.display3),
              Wrap(
                children: <Widget>[
                  _buildButtonExample(
                    context,
                    "enabled",
                    IrmaButton(
                      label: "Sign up",
                      onPressed: () {
                        debugPrint("pressed enabled button");
                      },
                    ),
                  ),
                  _buildButtonExample(
                    context,
                    "disabled",
                    IrmaButton(
                      label: "Sign up",
                      onPressed: null,
                      onPressedDisabled: () {
                        debugPrint("pressed disabled button");
                      },
                    ),
                  ),
                ],
              ),
              Text("Outlined", style: IrmaTheme.of(context).textTheme.display3),
              Wrap(
                children: <Widget>[
                  _buildButtonExample(
                    context,
                    "enabled",
                    IrmaOutlinedButton(
                      label: "Sign up",
                      onPressed: () {
                        debugPrint("pressed enabled button (outlined)");
                      },
                    ),
                  ),
                  _buildButtonExample(
                    context,
                    "disabled",
                    IrmaOutlinedButton(
                      label: "Sign up",
                      onPressedDisabled: () {
                        debugPrint("pressed disabled button (outlined)");
                      },
                    ),
                  ),
                ],
              ),
              Text("Text", style: IrmaTheme.of(context).textTheme.display3),
              const Text(
                "These do not work properly yet, text color changes are not available in Material Design Buttons so we need to build a custom component for that. IrmaTextButton is currently implemented using a Material FlatButton.",
              ),
              Wrap(
                children: <Widget>[
                  _buildButtonExample(
                    context,
                    "enabled",
                    IrmaTextButton(
                      label: "Sign up",
                      onPressed: () {},
                    ),
                  ),
                  _buildButtonExample(
                    context,
                    "disabled",
                    const IrmaTextButton(
                      label: "Sign up",
                    ),
                  ),
                ],
              ),
              Text("Button sizes", style: IrmaTheme.of(context).textTheme.display3),
              Wrap(
                children: <Widget>[
                  _buildButtonExample(
                    context,
                    "high priority",
                    IrmaButton(
                      label: "Sign up",
                      size: IrmaButtonSize.large,
                      onPressed: () {},
                    ),
                  ),
                  _buildButtonExample(
                    context,
                    "medium priority",
                    IrmaButton(
                      label: "Sign up",
                      size: IrmaButtonSize.medium,
                      onPressed: () {},
                    ),
                  ),
                  _buildButtonExample(
                    context,
                    "low priority",
                    IrmaButton(
                      label: "Sign up",
                      size: IrmaButtonSize.small,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              Text("With an icon", style: IrmaTheme.of(context).textTheme.display3),
              Wrap(
                children: <Widget>[
                  _buildButtonExample(
                    context,
                    "contained",
                    IrmaButton(
                      label: "Sign up",
                      onPressed: () {},
                      icon: IrmaIcons.lock,
                    ),
                  ),
                  _buildButtonExample(
                    context,
                    "outlined",
                    IrmaOutlinedButton(
                      label: "Sign up",
                      onPressed: () {},
                      icon: IrmaIcons.lock,
                    ),
                  ),
                ],
              ),
              Text("Icon button", style: IrmaTheme.of(context).textTheme.display3),
              const Text("Not implemented yet."),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonExample(BuildContext context, String name, Widget button) {
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
