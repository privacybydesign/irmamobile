import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/models/native_events.dart';
import 'src/screens/add_data/add_data_screen.dart';
import 'src/screens/change_language/change_language_screen.dart';
import 'src/screens/change_pin/change_pin_screen.dart';
import 'src/screens/debug/debug_screen.dart';
import 'src/screens/enrollment/enrollment_screen.dart';
import 'src/screens/help/help_screen.dart';
import 'src/screens/home/home_screen.dart';
import 'src/screens/issue_wizard/issue_wizard.dart';
import 'src/screens/loading/loading_screen.dart';
import 'src/screens/reset_pin/reset_pin_screen.dart';
import 'src/screens/scanner/scanner_screen.dart';
import 'src/screens/session/session.dart';
import 'src/screens/session/session_screen.dart';
import 'src/screens/session/unknown_session_screen.dart';
import 'src/screens/settings/settings_screen.dart';
import 'src/widgets/irma_repository_provider.dart';

class Routing {
  static Map<String, WidgetBuilder> simpleRoutes = {
    LoadingScreen.routeName: (context) => LoadingScreen(),
    EnrollmentScreen.routeName: (context) => EnrollmentScreen(),
    ScannerScreen.routeName: (context) => ScannerScreen(),
    ChangePinScreen.routeName: (context) => ChangePinScreen(),
    ChangeLanguageScreen.routeName: (context) => ChangeLanguageScreen(),
    SettingsScreen.routeName: (context) => SettingsScreen(),
    AddDataScreen.routeName: (context) => AddDataScreen(),
    HelpScreen.routeName: (context) => HelpScreen(),
    ResetPinScreen.routeName: (context) => ResetPinScreen(),
    DebugScreen.routeName: (context) => const DebugScreen(),
    HomeScreen.routeName: (context) => HomeScreen(),
  };

  // This function returns a `WidgetBuilder` of the screen found by `routeName`
  // It returns `null` if the screen is not found
  // It throws `ValueError` is it cannot properly cast the arguments
  static WidgetBuilder? _screenBuilder(String routeName, Object? arguments) {
    switch (routeName) {
      case SessionScreen.routeName:
        return (context) => SessionScreen(arguments: arguments as SessionScreenArguments);
      case UnknownSessionScreen.routeName:
        return (context) => UnknownSessionScreen(arguments: arguments as SessionScreenArguments);
      case IssueWizardScreen.routeName:
        return (context) => IssueWizardScreen(arguments: arguments as IssueWizardScreenArguments);

      default:
        return simpleRoutes[routeName];
    }
  }

  // Manually define what root routes are
  static bool _isRootRoute(RouteSettings settings) {
    return settings.name == HomeScreen.routeName || settings.name == EnrollmentScreen.routeName;
  }

  static bool _isSubnavigatorRoute(RouteSettings settings) {
    return settings.name == EnrollmentScreen.routeName || settings.name == ChangePinScreen.routeName;
  }

  static _canPop(RouteSettings settings, BuildContext context) {
    // If the current route has a subnavigator and is on the root, defer to that component's `PopScope`
    if (_isSubnavigatorRoute(settings) && _isRootRoute(settings)) {
      return true;
    }

    // Otherwise if it is a root route, background the app on backpress
    if (_isRootRoute(settings)) {
      if (settings.name == HomeScreen.routeName) {
        // Check if we are in the drawn state.
        // We don't want the app to background in this case.
        // Defer to home_screen.dart
        return true;
      }
      return false;
    }

    return true;
  }

  static Route generateRoute(RouteSettings settings) {
    // Try to find the appropriate screen, but keep `RouteNotFoundScreen` as default
    WidgetBuilder screenBuilder = (context) => const RouteNotFoundScreen();
    try {
      if (settings.name != null) screenBuilder = _screenBuilder(settings.name!, settings.arguments) ?? screenBuilder;
    } catch (_) {
      // pass
    }

    // Wrap the route in a `PopScope` that denies Android back presses
    // if the route is an initial route
    return MaterialPageRoute(
      builder: (BuildContext context) {
        return PopScope(
          canPop: _canPop(settings, context),
          onPopInvokedWithResult: (didPop, popResult) {
            if (_isRootRoute(settings) && settings.name != HomeScreen.routeName) {
              IrmaRepositoryProvider.of(context).bridgedDispatch(AndroidSendToBackgroundEvent());
            }
          },
          child: screenBuilder(context),
        );
      },
      settings: settings,
    );
  }
}

class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      throw Exception(
        'Route not found. Invalid route or invalid arguments were specified.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Page not found'),
      ),
      body: const Center(
        child: Text(''),
      ),
    );
  }
}
