import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/screens/about/about_screen.dart';
import 'package:irmamobile/src/screens/add_cards/card_store_screen.dart';
import 'package:irmamobile/src/screens/change_pin/change_pin_screen.dart';
import 'package:irmamobile/src/screens/debug/debug_screen.dart';
import 'package:irmamobile/src/screens/disclosure/disclosure_screen.dart';
import 'package:irmamobile/src/screens/disclosure/issuance_screen.dart';
import 'package:irmamobile/src/screens/disclosure/session.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/help/help_screen.dart';
import 'package:irmamobile/src/screens/history/history_screen.dart';
import 'package:irmamobile/src/screens/pin/pin_screen.dart';
import 'package:irmamobile/src/screens/reset_pin/reset_pin_screen.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:irmamobile/src/screens/wallet/wallet_screen.dart';

class Routing {
  static Map<String, WidgetBuilder> simpleRoutes = {
    WalletScreen.routeName: (context) => WalletScreen(),
    EnrollmentScreen.routeName: (context) => EnrollmentScreen(),
    PinScreen.routeName: (context) => const PinScreen(),
    ScannerScreen.routeName: (context) => ScannerScreen(),
    ChangePinScreen.routeName: (context) => ChangePinScreen(),
    AboutScreen.routeName: (context) => AboutScreen(),
    SettingsScreen.routeName: (context) => SettingsScreen(),
    CardStoreScreen.routeName: (context) => CardStoreScreen(),
    HistoryScreen.routeName: (context) => HistoryScreen(),
    HelpScreen.routeName: (context) => HelpScreen(),
    ResetPinScreen.routeName: (context) => ResetPinScreen(),
    DebugScreen.routeName: (context) => DebugScreen(),
  };

  static Route generateRoute(RouteSettings settings) {
    final arg = settings.arguments;

    debugPrint(settings.name);

    switch (settings.name) {
      case DisclosureScreen.routeName:
        if (arg is SessionScreenArguments) {
          return MaterialPageRoute(
            builder: (context) {
              return DisclosureScreen(arguments: arg);
            },
            settings: settings,
          );
        }
        return _errorPage();
      case IssuanceScreen.routeName:
        if (arg is SessionScreenArguments) {
          return MaterialPageRoute(
            builder: (context) {
              return IssuanceScreen(arguments: arg);
            },
            settings: settings,
          );
        }
        return _errorPage();
      default:
        final builder = simpleRoutes[settings.name];
        if (builder == null) {
          return _errorPage();
        }
        return MaterialPageRoute(
          builder: builder,
          settings: settings,
        );
    }
  }

  static MaterialPageRoute _errorPage() {
    if (kDebugMode) {
      throw Exception(
        "Ended up on error page during debug session, an invalid route or invalid arguments were specified.",
      );
    }

    return MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Error"),
          ),
          body: const Center(
            child: Text("Error"),
          ),
        );
      },
    );
  }
}
