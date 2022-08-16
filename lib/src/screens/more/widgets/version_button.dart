import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../sentry_dsn.dart';
import '../../../models/credentials.dart';
import '../../../theme/theme.dart';
import '../../../widgets/irma_repository_provider.dart';
import '../../../widgets/translated_text.dart';

class VersionButton extends StatelessWidget {
  final _developerModeTapStream = BehaviorSubject.seeded(0);

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
    final theme = IrmaTheme.of(context);

    void showDeveloperMode() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.success,
          content: const TranslatedText('more_tab.developer_mode_enabled'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      repo.preferences.setDeveloperModeVisible(true);
      repo.setDeveloperMode(true);
    }

    // throttle prevents multiple invocations of the dialog
    // when tapping furiously 
    const throttleTime = Duration(milliseconds: 100);

    _developerModeTapStream.throttleTime(throttleTime).listen((i) {
      if (i == 7) {
        showDeveloperMode();
      }
    });

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              _developerModeTapStream.value = _developerModeTapStream.value + 1;
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
                    return TranslatedText(
                      'more_tab.app_id',
                      translationParams: {
                        'id': appId ?? '',
                      },
                    );
                  },
                ),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (BuildContext context, AsyncSnapshot<PackageInfo> info) => TranslatedText(
                    'more_tab.version',
                    translationParams: {
                      'version': _buildVersionString(info),
                    },
                    style: theme.textTheme.bodyText2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
