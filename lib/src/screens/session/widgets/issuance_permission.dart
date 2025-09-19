import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/credentials.dart';
import '../../../theme/theme.dart';
import '../../../widgets/irma_bottom_bar.dart';
import '../../../widgets/irma_quote.dart';
import '../../../widgets/issuing_detail.dart';
import 'session_scaffold.dart';

class IssuancePermission extends StatelessWidget {
  final Function()? onDismiss;
  final Function()? onGivePermission;

  final bool satisfiable;
  final List<MultiFormatCredential> issuedCredentials;

  const IssuancePermission({
    super.key,
    this.onDismiss,
    this.onGivePermission,
    this.satisfiable = false,
    required this.issuedCredentials,
  });

  Widget _buildNavigationBar(BuildContext context) {
    return satisfiable
        ? IrmaBottomBar(
            primaryButtonLabel: FlutterI18n.translate(context, 'issuance.add'),
            onPrimaryPressed: () => onGivePermission?.call(),
            secondaryButtonLabel: FlutterI18n.translate(context, 'issuance.cancel'),
            onSecondaryPressed: () => onDismiss?.call(),
          )
        : IrmaBottomBar(
            primaryButtonLabel: FlutterI18n.translate(context, 'session.navigation_bar.back'),
            onPrimaryPressed: () => onDismiss?.call(),
          );
  }

  Widget _buildPermissionWidget(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
          child: IrmaQuote(
            quote: FlutterI18n.translate(
              context,
              'issuance.description',
            ),
          ),
        ),
        IssuingDetail(issuedCredentials),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => SessionScaffold(
        appBarTitle: 'issuance.title',
        bottomNavigationBar: _buildNavigationBar(context),
        body: _buildPermissionWidget(context),
        onDismiss: onDismiss,
      );
}
