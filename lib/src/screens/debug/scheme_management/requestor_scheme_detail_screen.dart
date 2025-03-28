import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/irma_configuration.dart';
import '../../../models/scheme_events.dart';
import '../../../providers/irma_repository_provider.dart';
import '../../../theme/theme.dart';
import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/irma_icon_button.dart';
import '../util/snackbar.dart';

class RequestorSchemeDetailScreen extends StatelessWidget {
  final RequestorScheme requestorScheme;

  const RequestorSchemeDetailScreen({super.key, required this.requestorScheme});

  void _onDeleteScheme(BuildContext context) {
    IrmaRepositoryProvider.of(context).bridgedDispatch(RemoveRequestorSchemeEvent(
      schemeId: requestorScheme.id,
    ));
    Navigator.of(context).pop();

    if (!context.mounted) return;
    showSnackbar(
      context,
      FlutterI18n.translate(
        context,
        'debug.scheme_management.remove',
        translationParams: {
          'scheme': requestorScheme.id,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      appBar: IrmaAppBar(
        title: requestorScheme.id,
        actions: [
          IrmaIconButton(
            icon: Icons.delete,
            onTap: () => _onDeleteScheme(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.screenPadding),
        child: Column(
          children: [
            ListTile(
              title: const Text('Type'),
              subtitle: Text(requestorScheme.demo ? 'Demo requestor scheme' : 'Production requestor scheme'),
            ),
          ],
        ),
      ),
    );
  }
}
