import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../models/credential_events.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../providers/irma_repository_provider.dart";
import "../../providers/schemaless_credentials_provider.dart";
import "../../theme/theme.dart";
import "../../widgets/base64_image.dart";
import "../../widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "../../widgets/credential_card/irma_credential_card_options_bottom_sheet.dart";
import "../../widgets/credential_card/yivi_credential_card.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_avatar.dart";
import "../../widgets/progress.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/yivi_bottom_sheet.dart";

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

  IrmaAppBar _buildAppBar(schemaless.Credential? credential) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final name = credential?.name.translate(lang) ?? "";

    // Drive the title's opacity directly from the scroll controller via
    // AnimatedBuilder, so updates stay scoped to the AppBar title and the
    // body's scroll view doesn't rebuild mid-drag (which would interrupt
    // the gesture and snap the scroll back).
    final titleContent = Row(
      mainAxisSize: .min,
      mainAxisAlignment: .center,
      spacing: theme.smallSpacing,
      children: [
        if (credential != null)
          Transform.translate(
            offset: Offset(0, 4),
            child: IrmaAvatar(
              logoImage: credential.image != null
                  ? Base64Image(base64: credential.image!.base64)
                  : null,
              initials: credential.image == null && name.isNotEmpty
                  ? name[0]
                  : null,
              size: 20,
            ),
          ),
        Text(
          name,
          style: theme.textTheme.displaySmall?.copyWith(color: theme.dark),
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
            duration: const Duration(milliseconds: 200),
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
    final provider = schemalessCredentialsWithIdProvider(
      widget.credentialTypeId,
    );
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

  SizedBox _buildCredentialsList(List<schemaless.Credential> credentials) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: .symmetric(horizontal: theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              SizedBox(height: theme.defaultSpacing),
              ...credentials.map((cred) {
                final isDeletable = cred.credentialInstanceIds.isNotEmpty;
                final isReobtainable = cred.issueUrl
                    .translate(lang, fallback: "")
                    .isNotEmpty;

                return Padding(
                  padding: .only(bottom: theme.defaultSpacing),
                  child: YiviCredentialCard.fromCredential(
                    credential: cred,
                    compact: false,
                    headerTrailing: isDeletable || isReobtainable
                        ? IconButton(
                            onPressed: () => _showCredentialOptionsBottomSheet(
                              context,
                              cred,
                            ),
                            icon: const Icon(Icons.more_horiz_sharp),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(),
                          )
                        : null,
                  ),
                );
              }),
              SizedBox(height: theme.largeSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCredentialOptionsBottomSheet(
    BuildContext context,
    schemaless.Credential cred,
  ) async {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final isReobtainable = cred.issueUrl
        .translate(lang, fallback: "")
        .isNotEmpty;

    showYiviBottomSheet(
      context: context,
      titleKey: "credential.options.title",
      minHeightFraction: 1 / 2,
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
    schemaless.Credential credential,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => DeleteCredentialConfirmationDialog(),
        ) ??
        false;
    if (confirmed && context.mounted) {
      _deleteCredential(context, credential);
      _showDeletedSnackbar();
    }
  }

  void _deleteCredential(
    BuildContext context,
    schemaless.Credential credential,
  ) {
    IrmaRepositoryProvider.of(context).bridgedDispatch(
      DeleteCredentialEvent(hashByFormat: credential.credentialInstanceIds),
    );
  }

  void _showDeletedSnackbar() {
    final theme = IrmaTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TranslatedText(
          "credential.options.delete_success",
          style: theme.themeData.textTheme.bodyMedium!.copyWith(
            color: theme.light,
          ),
        ),
        behavior: .floating,
        backgroundColor: theme.themeData.colorScheme.secondary,
      ),
    );
  }

  void _reobtainCredential(
    BuildContext context,
    schemaless.Credential credential,
  ) {
    IrmaRepositoryProvider.of(
      context,
    ).openIssueURL(context, credential.credentialId, credential.issueUrl, ref);
  }
}
