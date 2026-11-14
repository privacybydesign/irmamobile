import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../models/credential.dart";
import "../../providers/credentials_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../theme/theme.dart";
import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/i18n.dart";
import "../../widgets/app_toast.dart";
import "../../widgets/base64_image.dart";
import "../../widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "../../widgets/credential_card/irma_credential_card_options_bottom_sheet.dart";
import "../../widgets/credential_card/yivi_credential_card.dart";
import "../../widgets/glass/glass_sheet.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_avatar.dart";
import "../../widgets/progress.dart";
import "../add_data/add_data_sheet.dart";

class SchemalessCredentialsDetailsScreen extends ConsumerStatefulWidget {
  final String credentialTypeId;

  const SchemalessCredentialsDetailsScreen({required this.credentialTypeId});

  @override
  ConsumerState<SchemalessCredentialsDetailsScreen> createState() =>
      _CredentialsDetailsScreenState();
}

class _CredentialsDetailsScreenState
    extends ConsumerState<SchemalessCredentialsDetailsScreen> {
  static const _scrollUnderThreshold = 100.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IrmaAppBar _buildAppBar(Credential? credential) {
    final theme = IrmaTheme.of(context);
    final name = credential?.name ?? "";

    // Drive the title's opacity directly from the scroll controller via
    // AnimatedBuilder, so updates stay scoped to the AppBar title and the
    // body's scroll view doesn't rebuild mid-drag (which would interrupt
    // the gesture and snap the scroll back).
    final titleContent = Row(
      mainAxisSize: .min,
      mainAxisAlignment: .center,
      spacing: YiviSpace.x8,
      children: [
        if (credential != null)
          Transform.translate(
            offset: const Offset(0, 4),
            child: IrmaAvatar(
              logoImage: credential.image != null
                  ? Base64Image(
                      base64: credential.image!.base64,
                      mimeType: credential.image!.mimeType,
                    )
                  : null,
              initials: credential.image == null && name.isNotEmpty
                  ? name[0]
                  : null,
              size: 20,
            ),
          ),
        Text(
          name,
          style: theme.textTheme.displaySmall?.copyWith(
            color: YiviPalette.of(context).text,
          ),
        ),
      ],
    );

    return IrmaAppBar(
      title: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) {
          final pastThreshold =
              credential != null &&
              _scrollController.hasClients &&
              _scrollController.position.pixels > _scrollUnderThreshold;
          return AnimatedOpacity(
            opacity: pastThreshold ? 1.0 : 0.0,
            duration: YiviMotion.quick,
            child: child,
          );
        },
        child: titleContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final provider = credentialsWithIdProvider(widget.credentialTypeId);
    final credentials = ref.watch(provider);

    ref.listen(provider, (_, creds) {
      // when there are no credentials (e.g. when they were all removed) we should go back to the previous page
      if (creds case AsyncData(value: []) when context.canPop()) {
        context.pop();
      }
    });

    final credential = switch (credentials) {
      AsyncData(:final value) => value.firstOrNull,
      _ => null,
    };

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.backgroundTertiary,
      appBar: _buildAppBar(credential),
      body: switch (credentials) {
        AsyncData(:final value) => _buildCredentialsList(value),
        AsyncError(:final error) => Center(child: Text(error.toString())),
        _ => IrmaProgress(),
      },
    );
  }

  SizedBox _buildCredentialsList(List<Credential> credentials) {
    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const .symmetric(horizontal: YiviSpace.x16),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const SizedBox(height: YiviSpace.x16),
              ...credentials.map((cred) {
                final isDeletable = cred.credentialInstanceIds.isNotEmpty;
                final isReobtainable = (cred.issueUrl ?? "").isNotEmpty;

                return Padding(
                  padding: const .only(bottom: YiviSpace.x16),
                  child: YiviCredentialCard.fromCredential(
                    credential: cred,
                    headerTrailing: isDeletable || isReobtainable
                        ? PlainIconButton(
                            icon: Icons.more_horiz_rounded,
                            semanticsLabel: MaterialLocalizations.of(
                              context,
                            ).moreButtonTooltip,
                            onPressed: () => _showCredentialOptionsBottomSheet(
                              context,
                              cred,
                            ),
                          )
                        : null,
                  ),
                );
              }),
              const SizedBox(height: YiviSpace.x32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCredentialOptionsBottomSheet(
    BuildContext context,
    Credential cred,
  ) async {
    final isReobtainable = (cred.issueUrl ?? "").isNotEmpty;

    showTitledGlassSheet(
      context: context,
      titleKey: "credential.options.title",
      child: IrmaCredentialCardOptionsBottomSheet(
        onDelete: cred.credentialInstanceIds.isEmpty
            ? null
            : () async {
                Navigator.of(context).pop();
                await _showConfirmDeleteDialog(
                  _scaffoldKey.currentContext!,
                  cred,
                );
              },
        onReobtain: !isReobtainable
            ? null
            : () {
                Navigator.of(context).pop();
                _reobtainCredential(context, cred);
              },
      ),
    );
  }

  Future<void> _showConfirmDeleteDialog(
    BuildContext context,
    Credential credential,
  ) async {
    final deleted = await confirmAndDeleteCredential(
      context,
      IrmaRepositoryProvider.of(context),
      credential.credentialInstanceIds,
    );
    if (deleted) _showDeletedSnackbar();
  }

  void _showDeletedSnackbar() =>
      showAppToast(context, context.tr("credential.options.delete_success"));

  void _reobtainCredential(BuildContext context, Credential credential) {
    obtainAgain(
      context,
      ref,
      credentialId: credential.credentialId,
      issueUrl: credential.issueUrl,
      card: credential,
    );
  }
}
