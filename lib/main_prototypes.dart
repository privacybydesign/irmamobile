import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    final List<LocalizationsDelegate> localizationsDelegates = [
      FlutterI18nDelegate(
        fallbackFile: 'nl',
        path: 'assets/locales',
      ),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate
    ];

    return IrmaTheme(
      builder: (context) {
        return MaterialApp(
          key: const Key("app"),
          title: 'IRMA',
          theme: IrmaTheme.of(context).themeData,
          localizationsDelegates: localizationsDelegates,
          supportedLocales: const [Locale('nl')],
          initialRoute: PrototypesScreen.routeName,
          routes: routes,
        );
      },
    );
  }
}
