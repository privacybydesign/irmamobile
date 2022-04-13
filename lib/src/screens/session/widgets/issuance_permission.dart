// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/screens/session/widgets/session_scaffold.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/issuing_detail.dart';

class IssuancePermission extends StatelessWidget {
  final Function() onDismiss;
  final Function() onGivePermission;

  final bool satisfiable;
  final List<Credential> issuedCredentials;

  const IssuancePermission({Key key, this.onDismiss, this.onGivePermission, this.satisfiable, this.issuedCredentials})
      : super(key: key);

  Widget _buildNavigationBar(BuildContext context) {
    return satisfiable
        ? IrmaBottomBar(
            key: const Key("issuance_accept"),
            primaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.yes"),
            onPrimaryPressed: () => onGivePermission(),
            secondaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.no"),
            onSecondaryPressed: () => onDismiss(),
          )
        : IrmaBottomBar(
            primaryButtonLabel: FlutterI18n.translate(context, "session.navigation_bar.back"),
            onPrimaryPressed: () => onDismiss(),
          );
  }

  Widget _buildPermissionWidget(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: theme.mediumSpacing,
            horizontal: theme.defaultSpacing,
          ),
          child: Text(
            FlutterI18n.plural(context, 'issuance.header', issuedCredentials.length),
            style: theme.textTheme.bodyText2,
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
