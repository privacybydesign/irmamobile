import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/credential_events.dart';
import '../../models/credentials.dart';
import '../../providers/credentials_provider.dart';
import '../../providers/irma_repository_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/credential_card/delete_credential_confirmation_dialog.dart';
import '../../widgets/credential_card/irma_credential_card_options_bottom_sheet.dart';
import '../../widgets/credential_card/yivi_credential_card.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_avatar.dart';
import '../../widgets/progress.dart';
import '../../widgets/translated_text.dart';

class CredentialsDetailsScreen extends ConsumerStatefulWidget {
  final String categoryName;
  final String credentialTypeId;

  const CredentialsDetailsScreen({required this.categoryName, required this.credentialTypeId});

  @override
  ConsumerState<CredentialsDetailsScreen> createState() => _CredentialsDetailsScreenState();
}

class _CredentialsDetailsScreenState extends ConsumerState<CredentialsDetailsScreen> {
  static const _scrollUnderThreshold = 200.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _scrollController = ScrollController();
  bool _scrollUnder = false;

  void _scrollListener() {
    if (_scrollController.offset > _scrollUnderThreshold) {
      if (!_scrollUnder) {
        setState(() {
          _scrollUnder = true;
        });
      }
    } else {
      if (_scrollUnder) {
        setState(() {
          _scrollUnder = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.removeListener(_scrollListener);
  }

  IrmaAppBar _createTitle(MultiFormatCredential c) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final name = c.credentialType.name.translate(lang);
    final theme = IrmaTheme.of(context);
    return IrmaAppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: theme.smallSpacing,
        children: [
          Transform.translate(
            offset: Offset(0, 4),
            child: IrmaAvatar(logoPath: c.credentialType.logo, size: 20),
          ),
          Text(name, style: theme.textTheme.displaySmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final provider = credentialsForTypeProvider(widget.credentialTypeId);
    final credentials = ref.watch(provider);

    ref.listen(provider, (_, creds) {
      // when there are no credentials (e.g. when they were all removed) we should go back to the previous page
      if (creds case AsyncData(value: [])) {
        context.pop();
      }
    });

    final IrmaAppBar? appBar = switch (credentials) {
      AsyncData(:final value) => value.firstOrNull != null && _scrollUnder ? _createTitle(value.first) : null,
      _ => null,
    };

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.backgroundTertiary,
      appBar: appBar ?? IrmaAppBar(title: Container()),
      body: switch (credentials) {
        AsyncData(:final value) => _buildCredentialsList(value),
        AsyncError(:final error) => Center(child: Text(error.toString())),
        _ => IrmaProgress(),
      },
    );
  }

  SizedBox _buildCredentialsList(List<MultiFormatCredential> credentials) {
    final theme = IrmaTheme.of(context);
    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: theme.defaultSpacing,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: theme.defaultSpacing,
              ),
              ...credentials.map(
                (cred) => Padding(
                  padding: EdgeInsets.only(bottom: theme.defaultSpacing),
                  child: YiviCredentialCard.fromMultiFormatCredential(
                    cred,
                    headerTrailing:
                        // Credential must either be reobtainable or deletable
                        // for the options bottom sheet to be accessible
                        cred.credentialType.disallowDelete && cred.credentialType.issueUrl.isEmpty
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
              ),
              SizedBox(
                height: theme.largeSpacing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCredentialOptionsBottomSheet(BuildContext context, MultiFormatCredential cred) async {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => IrmaCredentialCardOptionsBottomSheet(
        onDelete: cred.credentialType.disallowDelete
            ? null
            : () async {
                Navigator.of(context).pop();
                await _showConfirmDeleteDialog(_scaffoldKey.currentContext!, cred);
              },
        onReobtain: cred.credentialType.issueUrl.isEmpty
            ? null
            : () {
                Navigator.of(context).pop();
                _reobtainCredential(context, cred);
              },
      ),
    );
  }

  Future<void> _showConfirmDeleteDialog(BuildContext context, MultiFormatCredential credential) async {
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

  void _deleteCredential(BuildContext context, MultiFormatCredential credential) {
    if (!credential.credentialType.disallowDelete) {
      IrmaRepositoryProvider.of(context).bridgedDispatch(
        DeleteCredentialEvent(hashByFormat: credential.hashByFormat),
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

  void _reobtainCredential(BuildContext context, MultiFormatCredential credential) {
    if (credential.credentialType.issueUrl.isNotEmpty) {
      IrmaRepositoryProvider.of(context).openIssueURL(context, credential.credentialType.fullId);
    }
  }
}
