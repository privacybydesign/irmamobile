import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet_drawer.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

void startPrototype26(BuildContext context) {
  // Start this experiment in locked state
  IrmaRepository.get().lock();

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          drawer: WalletDrawer(),
          appBar: AppBar(
            title: const Text('Drawer example'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Container(
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Open the drawer in the top-left corner."),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IrmaButton(
                  icon: IrmaIcons.chevronLeft,
                  label: "Close example",
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              )
            ],
          ),
        );
      },
    ),
  );
}
