import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:package_info/package_info.dart';

import '../../../../sentry_dsn.dart';

class VersionButton extends StatefulWidget {
  @override
  _VersionButtonState createState() => _VersionButtonState();
}

class _VersionButtonState extends State<VersionButton> {
  int tappedCount = 0;

  String buildVersionString(AsyncSnapshot<PackageInfo> info) {
    String buildHash = version.substring(0, version != 'debugbuild' && 8 < version.length ? 8 : version.length);
    if (info.hasData) {
      return "${info.data.version} (${info.data.buildNumber}, $buildHash)";
    } else {
      return "($buildHash)";
    }
  }

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
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (BuildContext context, AsyncSnapshot<PackageInfo> info) => Text(
                  FlutterI18n.translate(context, 'about.version', translationParams: {
                    'version': buildVersionString(info),
                  }),
                  style: Theme.of(context).textTheme.body1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
