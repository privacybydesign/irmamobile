import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:package_info/package_info.dart';

import '../../../../sentry_dsn.dart';

class VersionButton extends StatefulWidget {
  @override
  _VersionButtonState createState() => _VersionButtonState();
}

class _VersionButtonState extends State<VersionButton> {
  int tappedCount = 0;

  String buildVersionString(AsyncSnapshot<PackageInfo> info) {
    final String buildHash = version.substring(0, version != 'debugbuild' && 8 < version.length ? 8 : version.length);
    if (info.hasData) {
      return '${info.data?.version} (${info.data?.buildNumber}, $buildHash)';
    } else {
      return '($buildHash)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: InkWell(
              onTap: () {
                setState(() {
                  tappedCount++;
                  if (tappedCount == 7) {
                    tappedCount = 0;
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(FlutterI18n.translate(context, 'app_tab.developer_mode_enabled'))));
                    IrmaPreferences.get().setDeveloperModeVisible(true);
                    IrmaRepository.get().setDeveloperMode(true);
                  }
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<Credentials>(
                    stream: IrmaRepository.get().getCredentials(),
                    builder: (context, credentials) {
                      String? appId;
                      if (credentials.hasData) {
                        final keyShareCred =
                            credentials.data?.values.firstWhereOrNull((cred) => cred.isKeyshareCredential);
                        appId = keyShareCred?.attributes.values.first.raw;
                      }
                      return Text(
                        FlutterI18n.translate(context, 'app_tab.app_id', translationParams: {
                          'id': appId ?? '',
                        }),
                        style: Theme.of(context).textTheme.bodyText2,
                      );
                    },
                  ),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (BuildContext context, AsyncSnapshot<PackageInfo> info) => Text(
                      FlutterI18n.translate(context, 'app_tab.version', translationParams: {
                        'version': buildVersionString(info),
                      }),
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ),
                ],
              )),
        ),
      ],
    );
  }
}
