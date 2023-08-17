import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/enrollment_events.dart';
import '../../../models/irma_configuration.dart';
import '../../../theme/theme.dart';
import '../../../util/combine.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/irma_icon_button.dart';
import '../../../widgets/irma_repository_provider.dart';
import '../../../widgets/progress.dart';
import '../../../widgets/translated_text.dart';
import 'add_scheme_dialog.dart';

class SchemeManagementScreen extends StatelessWidget {
  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _onAddScheme(BuildContext context) async {
    final newSchemeUrl = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AddSchemeDialog(controller: controller);
      },
    );

    if (newSchemeUrl == null) return;

    String publicKey = '';
    try {
      final Uri uri = Uri.parse('$newSchemeUrl/pk.pem');
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      publicKey = await response.transform(utf8.decoder).first;
      if (response.statusCode != 200) {
        throw 'HTTP status code ${response.statusCode} received';
      }
    } catch (e) {
      _showSnackbar(context, 'Error while fetching scheme: ${e.toString()}.');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = IrmaRepositoryProvider.of(context);
    final theme = IrmaTheme.of(context);

    return Scaffold(
      appBar: IrmaAppBar(
        titleTranslationKey: 'debug.scheme_management.title',
        actions: [
          IrmaIconButton(
            icon: Icons.add,
            onTap: () => _onAddScheme(context),
          )
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<CombinedState2<EnrollmentStatusEvent, IrmaConfiguration>>(
          stream: combine2(repo.getEnrollmentStatusEvent(), repo.getIrmaConfiguration()),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: IrmaProgress(),
              );
            }
            final enrollmentStatus = snapshot.data!.a;
            final irmaConfiguration = snapshot.data!.b;

            // The demo flag can also be set for keyshare schemes, so we have to look at the keyshareServer field
            final demoSchemes = irmaConfiguration.schemeManagers.entries
                .where((entry) => entry.value.keyshareServer.isEmpty)
                .map((entry) => entry.key);
            final nonDefaultEnrolledSchemes =
                enrollmentStatus.enrolledSchemeManagerIds.where((schemeId) => schemeId != repo.defaultKeyshareScheme);

            return ListView(
              padding: EdgeInsets.all(theme.defaultSpacing),
              children: [
                const TranslatedText('debug.scheme_management.active_schemes'),
                ListTile(
                  title: Text(repo.defaultKeyshareScheme),
                  subtitle: Text('Default keyshare scheme', style: theme.textTheme.caption),
                  onTap: () {},
                ),
                for (final schemeId in demoSchemes)
                  ListTile(
                    title: Text(schemeId),
                    // TODO: irmago cannot uninstall demo schemes yet.
                    subtitle: Text('Demo scheme (cannot be edited yet)', style: theme.textTheme.caption),
                  ),
                for (final schemeId in nonDefaultEnrolledSchemes)
                  ListTile(
                    title: Text(schemeId),
                    subtitle: Text('Keyshare scheme', style: theme.textTheme.caption),
                    onTap: () {},
                  ),
                if (enrollmentStatus.unenrolledSchemeManagerIds.isNotEmpty) const Text('Inactive schemes:'),
                for (final schemeId in enrollmentStatus.unenrolledSchemeManagerIds)
                  ListTile(
                    title: Text(schemeId),
                    subtitle: Text('Keyshare scheme', style: theme.textTheme.caption),
                    // TODO: irmago cannot uninstall inactive schemes yet.
                    onTap: () {},
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
