import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/screens/session/widgets/session_scaffold.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/issuing_detail.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class IssuancePermission extends StatelessWidget {
  final Function()? onDismiss;
  final Function()? onGivePermission;

  final bool satisfiable;
  final List<Credential> issuedCredentials;

  const IssuancePermission({
    Key? key,
    this.onDismiss,
    this.onGivePermission,
    this.satisfiable = false,
    required this.issuedCredentials,
  }) : super(key: key);

  Widget _buildNavigationBar(BuildContext context) {
    return satisfiable
        ? IrmaBottomBar(
            key: const Key("issuance_accept"),
            primaryButtonLabel: FlutterI18n.translate(context, "issuance.add"),
            onPrimaryPressed: () => onGivePermission?.call(),
            secondaryButtonLabel: FlutterI18n.translate(context, "issuance.cancel"),
            onSecondaryPressed: () => onDismiss?.call(),
          )
        : IrmaBottomBar(
            primaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.back"),
            onPrimaryPressed: () => onDismiss?.call(),
          );
  }

  Widget _buildPermissionWidget(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
      children: <Widget>[
        Padding(
            padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
            child: Container(
              color: theme.lightBlue,
              padding: EdgeInsets.all(theme.defaultSpacing),
              child: TranslatedText(
                'issuance.description',
                style: theme.textTheme.caption,
              ),
            )),
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
