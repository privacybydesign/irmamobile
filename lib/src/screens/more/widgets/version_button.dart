import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

import '../../../../sentry_dsn.dart';
import '../../../models/credentials.dart';
import '../../../theme/theme.dart';
import '../../../widgets/irma_repository_provider.dart';
import '../../../widgets/translated_text.dart';

class VersionButton extends StatefulWidget {
  const VersionButton({
    Key? key,
  }) : super(key: key);

  @override
  _VersionButtonState createState() => _VersionButtonState();
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

    final textStyle = theme.textTheme.headline6!.copyWith(
      fontWeight: FontWeight.w600,
    );

    void _showSnackbar(String translationKey) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.success,
            content: TranslatedText(translationKey),
            behavior: SnackBarBehavior.floating,
          ),
        );

    void _onTap() async {
      _tapCounter++;

      if (_tapCounter == 7) {
        _tapCounter = 0;

        final inDeveloperMode = await repo.getDeveloperMode().first;
        if (inDeveloperMode) {
          _showSnackbar('more_tab.developer_mode_already_enabled');
        } else {
          _showSnackbar('more_tab.developer_mode_enabled');
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
              onTap: _onTap,
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
                        appId = keyShareCred?.attributes.first.value.raw;
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
