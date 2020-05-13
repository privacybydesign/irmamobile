import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';

import '../../../../sentry_dsn.dart';

class VersionButton extends StatefulWidget {
  @override
  _VersionButtonState createState() => _VersionButtonState();
}

class _VersionButtonState extends State<VersionButton> {
  int tappedCount = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            child: InkWell(
              onTap: () {
                setState(() {
                  tappedCount++;
                  if (tappedCount == 7) {
                    tappedCount = 0;
                    Scaffold.of(context).showSnackBar(
                        SnackBar(content: Text(FlutterI18n.translate(context, 'about.developer_mode_enabled'))));
                    IrmaPreferences.get().setDeveloperModeVisible(true);
                    IrmaRepository.get().setDeveloperMode(true);
                  }
                });
              },
              child: Text(
                FlutterI18n.translate(context, 'about.version', translationParams: {
                  'version': version.substring(
                    0,
                    version != 'debugbuild' && 8 < version.length ? 8 : version.length,
                  )
                }),
                style: Theme.of(context).textTheme.body1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
