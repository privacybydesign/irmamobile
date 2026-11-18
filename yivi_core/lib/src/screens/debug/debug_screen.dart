import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../data/irma_repository.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/wallet_cards_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/i18n.dart";
import "../../widgets/bars/irma_app_bar.dart";
import "../../widgets/feedback/glass_dialog.dart";
import "../../widgets/surfaces/glass_group.dart";
import "../more/widgets/tiles.dart";
import "cert_management/cert_management_screen.dart";
import "debug_helper.dart";
import "debug_schemes.dart";
import "scheme_management/scheme_management_screen.dart";
import "session/session_helper_screen.dart";
import "util/snackbar.dart";
import "widgets/card_motion_sliders.dart";
import "widgets/local_backends_tile.dart";

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
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
    // Asks for the schemes now, so they are there when a button needs them.
    ref.listenManual(debugSchemesProvider, (_, _) {});
  }

  /// Builds a debug issuance request from the schemes, once they are there.
  Future<String> _issuanceRequest(
    Future<String> Function(DebugHelper helper) build,
  ) async =>
      build(DebugHelper(schemes: await ref.read(debugSchemesProvider.future)));

  Future<void> _deleteAllDeletableCards(IrmaRepository repo) async {
    final confirmed = await showConfirmDialog(
      context,
      destructive: true,
      titleKey: "debug.delete_credentials.dialog.title",
      messageKey: "debug.delete_credentials.dialog.content",
    );

    if (!confirmed) return;

    // A card without instance ids cannot be deleted, as on its details.
    for (final card in ref.read(walletCardsProvider)) {
      if (card.credentialInstanceIds.isEmpty) continue;
      repo.deleteCredential(card.credentialInstanceIds);
    }

    if (!mounted) return;
    showSnackbar(context, context.tr("debug.delete_credentials.success"));
  }

  void _onOpenSchemeManagement() async {
    final confirmed = await showConfirmDialog(
      context,
      titleKey: "debug.scheme_management.warning_dialog.title",
      messageKey: "debug.scheme_management.warning_dialog.content",
    );

    if (confirmed && mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => SchemeManagementScreen()));
    }
  }

  void _onOpenCertManagement() async {
    final confirmed = await showConfirmDialog(
      context,
      titleKey: "debug.cert_management.warning_dialog.title",
      messageKey: "debug.cert_management.warning_dialog.content",
    );

    if (confirmed && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => CertificateManagementScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = repositoryOf(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: YiviPalette.of(context).background,
      appBar: IrmaAppBar(titleTranslationKey: "debug.title"),
      body: BarInsetsBuilder(
        builder: (context, insets) => ListView(
          padding:
              insets +
              const EdgeInsets.fromLTRB(
                YiviSpace.x16,
                YiviSpace.x8,
                YiviSpace.x16,
                YiviSpace.x48,
              ),
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
                const LocalBackendsTile(),
              ],
            ),
            const SizedBox(height: YiviSpace.x24),
            GlassGroup(
              dividerIndent: 68,
              children: [
                _buildListTile(
                  Icons.badge,
                  "debug.issue_digid",
                  onTap: () async {
                    final digidIssuanceRequest = await _issuanceRequest(
                      (helper) => helper.digidProefIssuanceRequest(),
                    );
                    await repo.startTestSession(digidIssuanceRequest);
                  },
                ),
                _buildListTile(
                  Icons.exposure_plus_2,
                  "debug.random_issuance",
                  onTap: () async {
                    final randomIssuanceRequest = await _issuanceRequest(
                      (helper) => helper.randomIssuanceRequest(2),
                    );
                    await repo.startTestSession(randomIssuanceRequest);
                  },
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
              ],
            ),
            const SizedBox(height: YiviSpace.x24),
            const GlassGroup(children: [CardMotionSliders()]),
            const SizedBox(height: YiviSpace.x24),
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
