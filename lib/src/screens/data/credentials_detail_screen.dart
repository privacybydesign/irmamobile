import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../data/irma_repository.dart';
import '../../models/credential_events.dart';
import '../../models/credentials.dart';
import '../../theme/theme.dart';
import '../../util/language.dart';
import '../../widgets/credential_card/delete_credential_confirmation_dialog.dart';
import '../../widgets/credential_card/irma_credential_card.dart';
import '../../widgets/credential_card/irma_credential_card_options_bottom_sheet.dart';
import '../../widgets/credential_card/models/card_expiry_date.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import '../../widgets/translated_text.dart';

class CredentialsDetailScreen extends StatefulWidget {
  final String categoryName;
  final String credentialTypeId;

  const CredentialsDetailScreen({
    required this.categoryName,
    required this.credentialTypeId,
  });

  @override
  State<CredentialsDetailScreen> createState() => _DataDetailScreenState();
}

class _DataDetailScreenState extends State<CredentialsDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final IrmaRepository repo;
  late final StreamSubscription<Credentials> credentialStreamSubscription;
  List<Credential> credentials = [];

  void _credentialStreamListener(Credentials newCredentials) => setState(() {
        credentials =
            newCredentials.values.where((cred) => cred.info.credentialType.fullId == widget.credentialTypeId).toList();
        if (credentials.isEmpty) Navigator.of(context).pop();
      });

  _showCredentialOptionsBottomSheet(Credential cred) async => showModalBottomSheet<void>(
        context: context,
        builder: (context) => IrmaCredentialCardOptionsBottomSheet(
          onDelete: () async {
            Navigator.of(context).pop();
            await _showConfirmDeleteDialog(context, cred);
          },
          onReobtain: () {
            Navigator.of(context).pop();
            _reobtainCredential(cred);
          },
        ),
      );

  Future<void> _showConfirmDeleteDialog(BuildContext context, Credential credential) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => DeleteCredentialConfirmationDialog(),
        ) ??
        false;
    if (confirmed) {
      _deleteCredential(credential);
      _showDeletedSnackbar();
    }
  }

  void _deleteCredential(Credential credential) {
    if (!credential.info.credentialType.disallowDelete) {
      repo.bridgedDispatch(
        DeleteCredentialEvent(hash: credential.hash),
      );
    }
  }

  void _showDeletedSnackbar() {
    final theme = IrmaTheme.of(context);
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      SnackBar(
        content: TranslatedText(
          'credential.options.delete_success',
          style: theme.themeData.textTheme.caption!.copyWith(color: theme.light),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.themeData.colorScheme.secondary,
      ),
    );
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
      credentialStreamSubscription = repo.getCredentials().listen(_credentialStreamListener);
    });
  }

  @override
  void dispose() {
    credentialStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        titleTranslationKey: widget.categoryName,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: theme.defaultSpacing,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
              child: Text(
                credentials.isNotEmpty ? getTranslation(context, credentials.first.info.credentialType.name) : '',
                style: theme.textTheme.headline4,
              ),
            ),
            ...credentials
                .map(
                  (cred) => IrmaCredentialCard.fromCredential(
                    cred,
                    headerTrailing: IconButton(
                      onPressed: () => _showCredentialOptionsBottomSheet(cred),
                      icon: const Icon(
                        Icons.more_horiz,
                      ),
                    ),
                    expiryDate: CardExpiryDate(cred.expires),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }
}
