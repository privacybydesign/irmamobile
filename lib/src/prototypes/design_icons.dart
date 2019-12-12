import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

void startDesignIcons(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) {
      return DesignIcons();
    }),
  );
}

class DesignIcons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Icons"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            children: <Widget>[
              _buildIcon(context, IrmaIcons.add),
              _buildIcon(context, IrmaIcons.alert),
              _buildIcon(context, IrmaIcons.arrowBack),
              _buildIcon(context, IrmaIcons.arrowFront),
              _buildIcon(context, IrmaIcons.birthdate),
              _buildIcon(context, IrmaIcons.car),
              _buildIcon(context, IrmaIcons.chevronDown),
              _buildIcon(context, IrmaIcons.chevronLeft),
              _buildIcon(context, IrmaIcons.chevronRight),
              _buildIcon(context, IrmaIcons.chevronUp),
              _buildIcon(context, IrmaIcons.close),
              _buildIcon(context, IrmaIcons.delete),
              _buildIcon(context, IrmaIcons.duration),
              _buildIcon(context, IrmaIcons.edit),
              _buildIcon(context, IrmaIcons.email),
              _buildIcon(context, IrmaIcons.expand),
              _buildIcon(context, IrmaIcons.favourite),
              _buildIcon(context, IrmaIcons.filter),
              _buildIcon(context, IrmaIcons.flag),
              _buildIcon(context, IrmaIcons.info),
              _buildIcon(context, IrmaIcons.invalid),
              _buildIcon(context, IrmaIcons.lock),
              _buildIcon(context, IrmaIcons.logout),
              _buildIcon(context, IrmaIcons.menu),
              _buildIcon(context, IrmaIcons.minus),
              _buildIcon(context, IrmaIcons.personal),
              _buildIcon(context, IrmaIcons.phone),
              _buildIcon(context, IrmaIcons.question),
              _buildIcon(context, IrmaIcons.scanQrcode),
              _buildIcon(context, IrmaIcons.search),
              _buildIcon(context, IrmaIcons.shrink),
              _buildIcon(context, IrmaIcons.synchronize),
              _buildIcon(context, IrmaIcons.time),
              _buildIcon(context, IrmaIcons.valid),
              _buildIcon(context, IrmaIcons.verticalNav),
              _buildIcon(context, IrmaIcons.view),
              _buildIcon(context, IrmaIcons.hide),
              _buildIcon(context, IrmaIcons.warning),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: IrmaTheme.of(context).grayscale80,
        child: Icon(
          icon,
          size: 48.0,
        ),
      ),
    );
  }
}
