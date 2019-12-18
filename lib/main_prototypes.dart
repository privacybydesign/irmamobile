import 'package:flutter/material.dart';
import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/data/irma_client_mock.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/prototypes/prototypes_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';

void main() => runApp(PrototypesApp());

class PrototypesApp extends StatelessWidget {
  final IrmaRepository repository = IrmaRepository(client: IrmaClientMock(versionUpdateAvailable: true));
  final Map<String, WidgetBuilder> routes = {
    PrototypesScreen.routeName: (BuildContext context) => PrototypesScreen(),
  };

  PrototypesApp();

  @override
  Widget build(BuildContext context) {
    return IrmaTheme(
      builder: (context) {
        return MaterialApp(
          key: const Key("app"),
          title: 'IRMA',
          theme: IrmaTheme.of(context).themeData,
          localizationsDelegates: App.defaultLocalizationsDelegates(),
          supportedLocales: App.defaultSupportedLocales(),
          locale: const Locale('nl', 'NL'),
          initialRoute: PrototypesScreen.routeName,
          routes: routes,
        );
      },
    );
  }
}
