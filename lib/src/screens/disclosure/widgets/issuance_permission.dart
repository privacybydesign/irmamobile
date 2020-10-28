import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/screens/disclosure/widgets/session_scaffold.dart';
import 'package:irmamobile/src/screens/history/widgets/issuing_detail.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

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
    return ListView(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: IrmaTheme.of(context).mediumSpacing,
            horizontal: IrmaTheme.of(context).defaultSpacing,
          ),
          child: Text(
            FlutterI18n.plural(context, 'issuance.header', issuedCredentials.length),
            style: IrmaTheme.of(context).textTheme.bodyText2,
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
