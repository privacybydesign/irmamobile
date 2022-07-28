import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:package_info/package_info.dart';

import '../../../../sentry_dsn.dart';
import '../../../models/credentials.dart';
import '../../../widgets/irma_repository_provider.dart';

class VersionButton extends StatelessWidget {
  final counterNotifier = ValueNotifier(0);

  String _buildVersionString(AsyncSnapshot<PackageInfo> info) {
    final String buildHash = version.substring(0, version != 'debugbuild' && 8 < version.length ? 8 : version.length);
    if (info.hasData) {
      return '${info.data?.version} (${info.data?.buildNumber}, $buildHash)';
    } else {
      return '($buildHash)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: counterNotifier,
      builder: (context, counter, _) => Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (counter == 7) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.green,
                    content: Text(FlutterI18n.translate(context, 'more_tab.developer_mode_enabled')),
                    behavior: SnackBarBehavior.floating,
                  ));
                  repo.preferences.setDeveloperModeVisible(true);
                  repo.setDeveloperMode(true);
                  counterNotifier.value = 0;
                }
                counterNotifier.value = counter++;
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<Credentials>(
                    stream: repo.getCredentials(),
                    builder: (context, credentials) {
                      String? appId;
                      if (credentials.hasData) {
                        final keyShareCred =
                            credentials.data?.values.firstWhereOrNull((cred) => cred.isKeyshareCredential);
                        appId = keyShareCred?.attributes.values.first.raw;
                      }
                      return Text(
                        FlutterI18n.translate(context, 'more_tab.app_id', translationParams: {
                          'id': appId ?? '',
                        }),
                        style: Theme.of(context).textTheme.bodyText2,
                      );
                    },
                  ),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (BuildContext context, AsyncSnapshot<PackageInfo> info) => Text(
                      FlutterI18n.translate(context, 'more_tab.version', translationParams: {
                        'version': _buildVersionString(info),
                      }),
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
