import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../data/irma_repository.dart';
import '../../models/credential_events.dart';
import '../../models/credentials.dart';
import '../../theme/theme.dart';
import '../../widgets/credential_card/delete_credential_confirmation_dialog.dart';
import '../../widgets/credential_card/irma_credential_card.dart';
import '../../widgets/credential_card/irma_credential_card_options_bottom_sheet.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';

class CredentialsDetailScreen extends StatefulWidget {
  final String credentialTypeId;

  const CredentialsDetailScreen({
    required this.credentialTypeId,
  });

  @override
  State<CredentialsDetailScreen> createState() => _DataDetailScreenState();
}

class _DataDetailScreenState extends State<CredentialsDetailScreen> {
  late final IrmaRepository repo;
  late final StreamSubscription<Credentials> credentialStreamSubscription;
  List<Credential> credentials = [];

  void _credentialStreamListener(Credentials newCredentials) => setState(() {
        credentials =
            newCredentials.values.where((cred) => cred.info.credentialType.fullId == widget.credentialTypeId).toList();
        if (credentials.isEmpty) Navigator.of(context).pop();
      });

  Future<void> _showConfirmDeleteDialog(BuildContext context, Credential credential) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => DeleteCredentialConfirmationDialog(),
        ) ??
        false;
    if (confirmed) _deleteCredential(credential);
  }

  void _deleteCredential(Credential credential) {
    if (!credential.info.credentialType.disallowDelete) {
      repo.bridgedDispatch(
        DeleteCredentialEvent(hash: credential.hash),
      );
    }
  }

  void _reobtainCredential(Credential credential) {
    if (credential.info.credentialType.issueUrl.isNotEmpty) {
      repo.openIssueURL(context, credential.info.fullId);
    }
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      repo = IrmaRepositoryProvider.of(context);
      credentialStreamSubscription =
          IrmaRepositoryProvider.of(context).getCredentials().listen(_credentialStreamListener);
    });
  }

  @override
  void dispose() {
    credentialStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IrmaAppBar(
        titleTranslationKey: 'data.detail.title',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: IrmaTheme.of(context).smallSpacing,
        ),
        child: Column(
          children: credentials
              .map(
                (cred) => IrmaCredentialCard.fromCredential(
                  cred,
                  headerTrailing: IconButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (context) => IrmaCredentialCardOptionsBottomSheet(
                        onDelete: () {
                          Navigator.of(context).pop();
                          _showConfirmDeleteDialog(context, cred);
                        },
                        onReobtain: () {
                          Navigator.of(context).pop();
                          _reobtainCredential(cred);
                        },
                      ),
                    ),
                    icon: const Icon(Icons.more_horiz),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
