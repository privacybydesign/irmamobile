import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/credential_events.dart';
import '../../models/credentials.dart';
import '../../theme/theme.dart';
import '../../widgets/credential_card/delete_credential_confirmation_dialog.dart';
import '../../widgets/credential_card/irma_credential_card.dart';
import '../../widgets/credential_card/irma_credential_card_options_bottom_sheet.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/translated_text.dart';

class CredentialsDetailsScreen extends StatefulWidget {
  final String categoryName;
  final String credentialTypeId;

  const CredentialsDetailsScreen({required this.categoryName, required this.credentialTypeId});

  @override
  State<CredentialsDetailsScreen> createState() => _CredentialsDetailsScreenState();
}

class _CredentialsDetailsScreenState extends State<CredentialsDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  _showCredentialOptionsBottomSheet(BuildContext context, Credential cred) async {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => IrmaCredentialCardOptionsBottomSheet(
        onDelete: cred.info.credentialType.disallowDelete
            ? null
            : () async {
                Navigator.of(context).pop();
                await _showConfirmDeleteDialog(_scaffoldKey.currentContext!, cred);
              },
        onReobtain: cred.info.credentialType.issueUrl.isEmpty
            ? null
            : () {
                Navigator.of(context).pop();
                _reobtainCredential(context, cred);
              },
      ),
    );
  }

  Future<void> _showConfirmDeleteDialog(BuildContext context, Credential credential) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => DeleteCredentialConfirmationDialog(),
        ) ??
        false;
    if (confirmed && context.mounted) {
      _deleteCredential(context, credential);
      _showDeletedSnackbar();
    }
  }

  void _deleteCredential(BuildContext context, Credential credential) {
    if (!credential.info.credentialType.disallowDelete) {
      IrmaRepositoryProvider.of(context).bridgedDispatch(
        DeleteCredentialEvent(hash: credential.hash),
      );
    }
  }

  void _showDeletedSnackbar() {
    final theme = IrmaTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TranslatedText(
          'credential.options.delete_success',
          style: theme.themeData.textTheme.bodyMedium!.copyWith(
            color: theme.light,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.themeData.colorScheme.secondary,
      ),
    );
  }

  void _reobtainCredential(BuildContext context, Credential credential) {
    if (credential.info.credentialType.issueUrl.isNotEmpty) {
      IrmaRepositoryProvider.of(context).openIssueURL(context, credential.info.fullId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final repo = IrmaRepositoryProvider.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: widget.categoryName,
      ),
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: theme.defaultSpacing,
          ),
          child: SafeArea(
            child: StreamBuilder(
              stream: repo.getCredentials(),
              builder: (context, AsyncSnapshot<Credentials> snapshot) {
                if (!snapshot.hasData) return Container();

                final filteredCredentials = snapshot.data!.values
                    .where((cred) => cred.info.credentialType.fullId == widget.credentialTypeId)
                    .toList();

                if (filteredCredentials.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
                  return Container();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: theme.mediumSpacing,
                    ),
                    ...filteredCredentials.map(
                      (cred) => IrmaCredentialCard.fromCredential(
                        cred,
                        headerTrailing:
                            // Credential must either be reobtainable or deletable
                            // for the options bottom sheet to be accessible
                            cred.info.credentialType.disallowDelete && cred.info.credentialType.issueUrl.isEmpty
                                ? null
                                : Transform.translate(
                                    offset: Offset(theme.smallSpacing, -10),
                                    child: IconButton(
                                      onPressed: () => _showCredentialOptionsBottomSheet(context, cred),
                                      icon: const Icon(
                                        Icons.more_horiz_sharp,
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                    SizedBox(
                      height: theme.mediumSpacing,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
