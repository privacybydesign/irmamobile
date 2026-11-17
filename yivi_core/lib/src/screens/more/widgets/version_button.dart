import "package:material_ui/material_ui.dart";
import "package:package_info_plus/package_info_plus.dart";

import "../../../../sentry_dsn.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/theme.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";
import "../../../widgets/app_toast.dart";
import "../../../widgets/translated_text.dart";

class VersionButton extends StatefulWidget {
  const VersionButton({super.key});

  @override
  State<VersionButton> createState() => _VersionButtonState();
}

class _VersionButtonState extends State<VersionButton> {
  int _tapCounter = 0;

  String _buildVersionString(AsyncSnapshot<PackageInfo> info) {
    final String buildHash = version.substring(
      0,
      version != "debugbuild" && 8 < version.length ? 8 : version.length,
    );
    if (info.hasData) {
      return "${info.data?.version} (${info.data?.buildNumber}, $buildHash)";
    } else {
      return "($buildHash)";
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = repositoryOf(context);
    final theme = IrmaTheme.of(context);

    final textStyle = theme.textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w600,
    );

    void showSnackbar(String translationKey) =>
        showAppToast(context, context.tr(translationKey), overTabBar: true);

    void onTap() async {
      _tapCounter++;

      if (_tapCounter == 7) {
        _tapCounter = 0;

        final inDeveloperMode = await repo.getDeveloperMode().first;
        if (inDeveloperMode) {
          showSnackbar("more_tab.developer_mode_already_enabled");
        } else {
          showSnackbar("more_tab.developer_mode_enabled");
          repo.setDeveloperMode(true);
        }
      }
    }

    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.only(left: YiviSpace.x16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<PackageInfo> info,
                          ) => TranslatedText(
                            "more_tab.version",
                            translationParams: {
                              "version": _buildVersionString(info),
                            },
                            style: textStyle,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
