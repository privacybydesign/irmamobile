import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import 'src/data/irma_mock_bridge.dart';
import 'src/data/irma_preferences.dart';
import 'src/data/irma_repository.dart';
import 'src/prototypes/prototypes_screen.dart';
import 'src/providers/irma_repository_provider.dart';
import 'src/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await IrmaPreferences.fromInstance(
    mostRecentTermsUrlNl: 'testurl',
    mostRecentTermsUrlEn: 'testurl',
  );
  preferences.markLatestTermsAsAccepted(true);

  final repository = IrmaRepository(
    client: IrmaMockBridge(),
    preferences: preferences,
  );

  runApp(ProviderScope(child: PrototypesApp(repository: repository)));
}

class PrototypesApp extends StatelessWidget {
  final Map<String, WidgetBuilder> routes = {
    PrototypesScreen.routeName: (BuildContext context) => PrototypesScreen(),
  };

  final IrmaRepository repository;

  PrototypesApp({required this.repository});

  @override
  Widget build(BuildContext context) => IrmaRepositoryProvider(
        repository: repository,
        child: IrmaTheme(
          builder: (context) {
            return MaterialApp(
              key: const Key('app'),
              title: 'Yivi',
              theme: IrmaTheme.of(context).themeData,
              localizationsDelegates: AppState.defaultLocalizationsDelegates(),
              supportedLocales: AppState.defaultSupportedLocales(),
              locale: const Locale('nl', 'NL'),
              initialRoute: PrototypesScreen.routeName,
              routes: routes,
            );
          },
        ),
      );
}
