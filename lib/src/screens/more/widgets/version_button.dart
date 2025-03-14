import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../sentry_dsn.dart';
import '../../../models/credentials.dart';
import '../../../providers/irma_repository_provider.dart';
import '../../../theme/theme.dart';
import '../../../widgets/translated_text.dart';

class VersionButton extends StatefulWidget {
  const VersionButton({
    super.key,
  });

  @override
  State<VersionButton> createState() => _VersionButtonState();
}

class _VersionButtonState extends State<VersionButton> {
  int _tapCounter = 0;

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

    final textStyle = theme.textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w600,
    );

    void showSnackbar(String translationKey) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.success,
            content: TranslatedText(translationKey),
            behavior: SnackBarBehavior.floating,
          ),
        );

    void onTap() async {
      _tapCounter++;

      if (_tapCounter == 7) {
        _tapCounter = 0;

        final inDeveloperMode = await repo.getDeveloperMode().first;
        if (inDeveloperMode) {
          showSnackbar('more_tab.developer_mode_already_enabled');
        } else {
          showSnackbar('more_tab.developer_mode_enabled');
          repo.setDeveloperMode(true);
        }
      }
    }

    return Semantics(
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<Credentials>(
                    stream: repo.getCredentials(),
                    builder: (context, credentials) {
                      String? appId;
                      if (credentials.hasData) {
                        final keyShareCred = credentials.data?.values.firstWhereOrNull(
                          (cred) => cred.isKeyshareCredential && cred.schemeManager.id == repo.defaultKeyshareScheme,
                        );
                        appId = keyShareCred?.attributes.firstOrNull?.value.raw;
                      }
                      return TranslatedText(
                        'more_tab.app_id',
                        style: textStyle,
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
                      style: textStyle,
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
