import "package:flutter/foundation.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../data/irma_repository.dart";
import "../../models/credential_events.dart";
import "../../models/session.dart";
import "../../prototypes/prototypes_screen.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/handle_pointer.dart";
import "../../util/navigation.dart";
import "../../widgets/glass/glass_group.dart";
import "../../widgets/irma_app_bar.dart";
import "../more/widgets/tiles.dart";
import "cert_management/cert_management_screen.dart";
import "cert_management/widgets/cert_management_warning_dialog.dart";
import "debug_helper.dart";
import "scheme_management/scheme_management_screen.dart";
import "scheme_management/widgets/scheme_management_warning_dialog.dart";
import "session/session_helper_screen.dart";
import "util/snackbar.dart";
import "widgets/delete_all_credentials_confirmation_dialog.dart";
import "widgets/local_backends_tile.dart";

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  late final DebugHelper _debugHelper;

  Widget _buildListTile(
    IconData icon,
    String translationKey, {
    required Function() onTap,
    bool danger = false,
    Key? key,
  }) => Tile(
    key: key,
    isLink: false,
    iconData: icon,
    labelTranslationKey: translationKey,
    danger: danger,
    onTap: onTap,
  );

  @override
  initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = IrmaRepositoryProvider.of(context);
      final config = await repo.getIrmaConfiguration().first;
      _debugHelper = DebugHelper(irmaConfig: config);
    });
  }

  // FIXME: make this compatible with new credential system
  Future<void> _deleteAllDeletableCards(IrmaRepository repo) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => DeleteAllCredentialsConfirmationDialog(),
        ) ??
        false;

    if (!confirmed) return;

    final credentials = await repo.getCredentials().first;

    for (final credential in credentials.values) {
      if (credential.info.credentialType.disallowDelete) {
        continue;
      }

      repo.bridgedDispatch(DeleteCredentialEvent(hashByFormat: {}));
    }

    if (!mounted) return;
    showSnackbar(
      context,
      FlutterI18n.translate(context, "debug.delete_credentials.success"),
    );
  }

  void _onOpenSchemeManagement() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => SchemeManagementWarningDialog(),
        ) ??
        false;

    if (confirmed && mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => SchemeManagementScreen()));
    }
  }

  void _onOpenCertManagement() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => CertManagementWarningDialog(),
        ) ??
        false;

    if (confirmed && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => CertificateManagementScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: YiviPalette.of(context).background,
      appBar: IrmaAppBar(titleTranslationKey: "debug.title"),
      body: BarInsetsBuilder(
        builder: (context, insets) => ListView(
          padding: insets + const EdgeInsets.fromLTRB(16, 8, 16, 48),
          children: [
            GlassGroup(
              dividerIndent: 68,
              children: [
                _buildListTile(
                  Icons.list_alt,
                  "debug.scheme_management.title",
                  onTap: _onOpenSchemeManagement,
                ),
                _buildListTile(
                  Icons.verified_outlined,
                  "debug.cert_management.title",
                  onTap: _onOpenCertManagement,
                ),
                // Debug-only labels are plain English.
                _buildListTile(
                  Icons.flag_outlined,
                  "Feature flags",
                  onTap: context.pushFeatureFlagsScreen,
                ),
                const LocalBackendsTile(),
              ],
            ),
            const SizedBox(height: 24),
            GlassGroup(
              dividerIndent: 68,
              children: [
                _buildListTile(
                  Icons.badge,
                  "debug.issue_digid",
                  onTap: () async {
                    final digidIssuanceRequest = await _debugHelper
                        .digidProefIssuanceRequest();
                    await repo.startTestSession(digidIssuanceRequest);
                  },
                ),
                _buildListTile(
                  Icons.exposure_plus_2,
                  "debug.random_issuance",
                  onTap: () async {
                    final randomIssuanceRequest = await _debugHelper
                        .randomIssuanceRequest(2);
                    await repo.startTestSession(randomIssuanceRequest);
                  },
                ),
                _buildListTile(
                  Icons.play_arrow,
                  "debug.custom_issue_wizard",
                  onTap: () => handlePointer(
                    context,
                    IssueWizardPointer(
                      "irma-demo-requestors.ivido.demo-client",
                    ),
                  ),
                ),
                _buildListTile(
                  Icons.share,
                  "debug.start_session",
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SessionHelperScreen(
                        initialRequest: DebugHelper.disclosureSessionRequest(),
                      ),
                    ),
                  ),
                ),
                // The screen gallery of main_prototypes.dart, in development
                // builds only.
                if (!kReleaseMode)
                  _buildListTile(
                    Icons.view_carousel_outlined,
                    "Preview screens",
                    key: const Key("debug_preview_screens"),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PrototypesScreen(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            GlassGroup(
              children: [
                _buildListTile(
                  Icons.delete_outline_rounded,
                  "debug.delete_credentials.delete",
                  danger: true,
                  onTap: () => _deleteAllDeletableCards(repo),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
