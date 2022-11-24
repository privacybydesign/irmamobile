import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_info_scaffold_body.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback onTapClose;
  final VoidCallback? onTapRetry;

  const NoInternetScreen({required this.onTapClose, this.onTapRetry})
      : super(key: const ValueKey('no_internet_screen'));

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onTapClose();
        return false;
      },
      child: Scaffold(
        appBar: IrmaAppBar(
          titleTranslationKey: 'error.details_title',
          leadingAction: onTapClose,
        ),
        body: const IrmaInfoScaffoldBody(
          imagePath: 'assets/error/no_connection_illustration.svg',
          titleTranslationKey: 'error.title',
          bodyTranslationKey: 'error.types.no_internet',
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: FlutterI18n.translate(context, 'error.button_back'),
          onPrimaryPressed: onTapClose,
          secondaryButtonLabel: onTapRetry == null ? null : FlutterI18n.translate(context, 'error.button_retry'),
          onSecondaryPressed: onTapRetry,
        ),
      ),
    );
  }
}
