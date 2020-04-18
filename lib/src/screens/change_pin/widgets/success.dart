import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/irma_outlined_button.dart';

class Success extends StatelessWidget {
  static const String routeName = 'change_pin/success';

  final void Function() cancel;

  const Success({@required this.cancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This screen intentionally doesn't container an AppBar, as this screen can be closed
      // to get the app bac back. Otherwise, strange routes such as the settings or side menu
      // could be pushed on top of this screen, where it doesn't make sense

      // TODO: get rid of duplicate code (disclosure_feedback_screen.dart is very similar)

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(),
          ),
          Icon(
            IrmaIcons.valid,
            size: 120,
            color: IrmaTheme.of(context).interactionValid,
          ),
          const SizedBox(height: 43),
          TranslatedText(
            "change_pin.success.title",
            style: Theme.of(context).textTheme.display3,
          ),
          const SizedBox(height: 10),
          TranslatedText(
            "change_pin.success.message",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 38),
          IrmaOutlinedButton(
            label: FlutterI18n.translate(context, "change_pin.success.continue"),
            // TODO: please check if this onPressed behavior makes sense
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
        ],
      ),
    );
  }
}
