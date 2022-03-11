// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:irmamobile/app.dart';
import 'package:irmamobile/src/data/irma_mock_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/theme/theme.dart';

class TestingApp extends StatelessWidget {
  final IrmaRepository repository;
  final WidgetBuilder builder;

  TestingApp({this.builder, IrmaPreferences preferences})
      : repository = IrmaRepository(
          client: IrmaMockBridge(),
          preferences: preferences,
        );

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
          localizationsDelegates: AppState.defaultLocalizationsDelegates(forcedLocale),
          supportedLocales: AppState.defaultSupportedLocales(),
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
