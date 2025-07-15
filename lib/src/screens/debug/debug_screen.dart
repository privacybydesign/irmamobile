import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../data/irma_repository.dart';
import '../../models/credential_events.dart';
import '../../models/session.dart';
import '../../providers/irma_repository_provider.dart';
import '../../util/handle_pointer.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/translated_text.dart';
import 'debug_helper.dart';
import 'scheme_management/scheme_management_screen.dart';
import 'scheme_management/widgets/scheme_management_warning_dialog.dart';
import 'session/session_helper_screen.dart';
import 'util/snackbar.dart';
import 'widgets/delete_all_credentials_confirmation_dialog.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  late final DebugHelper _debugHelper;

  Widget _buildListTile(IconData icon, String translationKey, {Function()? onTap}) =>
      ListTile(leading: Icon(icon), title: TranslatedText(translationKey), onTap: onTap);

  @override
  initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = IrmaRepositoryProvider.of(context);
      final config = await repo.getIrmaConfiguration().first;
      _debugHelper = DebugHelper(irmaConfig: config);
    });
  }

  Future<void> _deleteAllDeletableCards(IrmaRepository repo) async {
    final confirmed =
        await showDialog<bool>(context: context, builder: (context) => DeleteAllCredentialsConfirmationDialog()) ??
        false;

    if (!confirmed) return;

    final credentials = await repo.getCredentials().first;

    for (final credential in credentials.values) {
      if (credential.info.credentialType.disallowDelete) {
        continue;
      }

      repo.bridgedDispatch(DeleteCredentialEvent(hash: credential.hash));
    }

    if (!mounted) return;
    showSnackbar(context, FlutterI18n.translate(context, 'debug.delete_credentials.success'));
  }

  void _onOpenSchemeManagement() async {
    final confirmed =
        await showDialog<bool>(context: context, builder: (context) => SchemeManagementWarningDialog()) ?? false;

    if (confirmed && mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => SchemeManagementScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);

    return Scaffold(
      appBar: const IrmaAppBar(titleTranslationKey: 'debug.title'),
      body: ListView(
        children: [
          _buildListTile(Icons.list_alt, 'debug.scheme_management.title', onTap: _onOpenSchemeManagement),
          _buildListTile(
            Icons.badge,
            'debug.issue_digid',
            onTap: () async {
              final digidIssuanceRequest = await _debugHelper.digidProefIssuanceRequest();
              await repo.startTestSession(digidIssuanceRequest);
            },
          ),
          _buildListTile(
            Icons.exposure_plus_2,
            'debug.random_issuance',
            onTap: () async {
              final randomIssuanceRequest = await _debugHelper.randomIssuanceRequest(2);
              await repo.startTestSession(randomIssuanceRequest);
            },
          ),
          _buildListTile(
            Icons.play_arrow,
            'debug.custom_issue_wizard',
            onTap: () => handlePointer(context, IssueWizardPointer('irma-demo-requestors.ivido.demo-client')),
          ),
          _buildListTile(
            Icons.share,
            'debug.start_session',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SessionHelperScreen(initialRequest: DebugHelper.disclosureSessionRequest()),
              ),
            ),
          ),
          _buildListTile(Icons.delete, 'debug.delete_credentials.delete', onTap: () => _deleteAllDeletableCards(repo)),
        ],
      ),
    );
  }
}
