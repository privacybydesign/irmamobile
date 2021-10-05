// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:irmamobile/app.dart';
import 'package:irmamobile/src/data/irma_mock_bridge.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/prototypes/prototypes_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';

void main() => runApp(PrototypesApp());

class PrototypesApp extends StatelessWidget {
  final Map<String, WidgetBuilder> routes = {
    PrototypesScreen.routeName: (BuildContext context) => PrototypesScreen(),
  };

  PrototypesApp();

  @override
  Widget build(BuildContext context) {
    IrmaRepository(client: IrmaMockBridge());

    return IrmaTheme(
      builder: (context) {
        return MaterialApp(
          key: const Key("app"),
          title: 'IRMA',
          theme: IrmaTheme.of(context).themeData,
          localizationsDelegates: AppState.defaultLocalizationsDelegates(),
          supportedLocales: AppState.defaultSupportedLocales(),
          locale: const Locale('nl', 'NL'),
          initialRoute: PrototypesScreen.routeName,
          routes: routes,
        );
      },
    );
  }
}
