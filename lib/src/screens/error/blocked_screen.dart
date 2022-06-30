import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/clear_all_data_event.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_info_scaffold_body.dart';
import '../../widgets/irma_repository_provider.dart';

class BlockedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Disable popping of this screen, as popping this is unwanted
        // (only way forward is and should be a reset, giving accidental access
        // to the wallet of a blocked account is unreasonable, even though credentials
        // can no longer be used)
        return false;
      },
      child: Scaffold(
        appBar: IrmaAppBar(
          title: Text(
            FlutterI18n.translate(
              context,
              'error.details_title',
            ),
            textAlign: TextAlign.center,
          ),
          noLeading: true,
        ),
        body: IrmaInfoScaffoldBody(
          icon: Icons.block,
          iconColor: IrmaTheme.of(context).secondary,
          titleTranslationKey: 'error.title',
          bodyTranslationKey: 'error.types.blocked',
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: FlutterI18n.translate(context, 'error.button_reset'),
          onPrimaryPressed: () => IrmaRepositoryProvider.of(context).bridgedDispatch(ClearAllDataEvent()),
        ),
      ),
    );
  }
}
