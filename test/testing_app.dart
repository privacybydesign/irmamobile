import 'package:flutter/material.dart';
import 'package:irmamobile/main.dart';
import 'package:irmamobile/src/data/irma_client_mock.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/theme/theme.dart';

class TestingApp extends StatelessWidget {
  final IrmaRepository repository;
  final WidgetBuilder builder;

  TestingApp({this.builder, bool versionUpdateAvailable = true, bool versionUpdateRequired = false})
      : repository = IrmaRepository(
            client: IrmaClientMock(
                versionUpdateAvailable: versionUpdateAvailable, versionUpdateRequired: versionUpdateRequired)) {}

  @override
  Widget build(BuildContext context) {
    return IrmaTheme(
      builder: (context) {
        const Locale forcedLocale = Locale('nl', 'NL');
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          key: const Key("app"),
          title: 'IRMA',
          theme: IrmaTheme.of(context).themeData,
          localizationsDelegates: App.defaultLocalizationsDelegates(forcedLocale),
          supportedLocales: App.defaultSupportedLocales(),
          // We need to use the system locale here because of a bug in FlutterI18n
          locale: forcedLocale,
          initialRoute: '/',
          routes: {
            '/': builder,
          },
        );
      },
    );
  }
}
