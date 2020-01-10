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
  static double iconSize = 60.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Icons"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const Text("Basic IRMA Icons"),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    children: <Widget>[
                      _buildIcon(context, IrmaIcons.add, "add"),
                      _buildIcon(context, IrmaIcons.alert, "alert"),
                      _buildIcon(context, IrmaIcons.arrowBack, "arrowBack"),
                      _buildIcon(context, IrmaIcons.arrowFront, "arrowFront"),
                      _buildIcon(context, IrmaIcons.birthdate, "birthdate"),
                      _buildIcon(context, IrmaIcons.car, "car"),
                      _buildIcon(context, IrmaIcons.chevronDown, "chevronDown"),
                      _buildIcon(context, IrmaIcons.chevronLeft, "chevronLeft"),
                      _buildIcon(context, IrmaIcons.chevronRight, "chevronRight"),
                      _buildIcon(context, IrmaIcons.chevronUp, "chevronUp"),
                      _buildIcon(context, IrmaIcons.close, "close"),
                      _buildIcon(context, IrmaIcons.delete, "delete"),
                      _buildIcon(context, IrmaIcons.duration, "duration"),
                      _buildIcon(context, IrmaIcons.edit, "edit"),
                      _buildIcon(context, IrmaIcons.email, "email"),
                      _buildIcon(context, IrmaIcons.expand, "expand"),
                      _buildIcon(context, IrmaIcons.favourite, "favourite"),
                      _buildIcon(context, IrmaIcons.filter, "filter"),
                      _buildIcon(context, IrmaIcons.flag, "flag"),
                      _buildIcon(context, IrmaIcons.info, "info"),
                      _buildIcon(context, IrmaIcons.invalid, "invalid"),
                      _buildIcon(context, IrmaIcons.lock, "lock"),
                      _buildIcon(context, IrmaIcons.logout, "logout"),
                      _buildIcon(context, IrmaIcons.menu, "menu"),
                      _buildIcon(context, IrmaIcons.minus, "minus"),
                      _buildIcon(context, IrmaIcons.personal, "personal"),
                      _buildIcon(context, IrmaIcons.phone, "phone"),
                      _buildIcon(context, IrmaIcons.question, "question"),
                      _buildIcon(context, IrmaIcons.scanQrcode, "scanQrcode"),
                      _buildIcon(context, IrmaIcons.search, "search"),
                      _buildIcon(context, IrmaIcons.shrink, "shrink"),
                      _buildIcon(context, IrmaIcons.synchronize, "synchronize"),
                      _buildIcon(context, IrmaIcons.time, "time"),
                      _buildIcon(context, IrmaIcons.valid, "valid"),
                      _buildIcon(context, IrmaIcons.verticalNav, "verticalNav"),
                      _buildIcon(context, IrmaIcons.view, "view"),
                      _buildIcon(context, IrmaIcons.hideStripe, "hideStripe"),
                      _buildIcon(context, IrmaIcons.hide, "hide"),
                      _buildIcon(context, IrmaIcons.warning, "warning"),
                    ],
                  ),
                ),
              ),
              const Text("Composed IRMA Icons"),
              Container(
                color: Colors.white,
                child: Stack(
                  children: <Widget>[
                    Icon(
                      IrmaIcons.view,
                      size: iconSize,
                      color: Colors.grey,
                    ),
                    Icon(
                      IrmaIcons.hideStripe,
                      size: iconSize,
                      color: Colors.red,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, IconData icon, String name) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Icon(
                icon,
                color: Colors.red,
                size: iconSize,
              ),
              Container(
                color: Colors.white,
                child: ClipRect(
                  child: Icon(
                    icon,
                    size: iconSize,
                  ),
                ),
              ),
            ],
          ),
          Text(
            name,
            style: IrmaTheme.of(context).textTheme.caption.copyWith(fontSize: 8),
          ),
        ],
      ),
    );
  }
}
