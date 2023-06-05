import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/irma_repository.dart';
import '../../models/native_events.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import '../activity/activity_tab.dart';
import '../data/data_tab.dart';
import '../more/more_tab.dart';
import '../scanner/scanner_screen.dart';
import 'home_tab.dart';
import 'widgets/irma_nav_bar.dart';
import 'widgets/irma_qr_scan_button.dart';
import 'widgets/pending_pointer_listener.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  IrmaNavBarTab selectedTab = IrmaNavBarTab.home;

  void _changeTab(IrmaNavBarTab tab) => setState(
        () => selectedTab = tab,
      );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = IrmaRepositoryProvider.of(context);
      final navigator = Navigator.of(context);

      _maybeOpenQrScanner(repo, navigator);
    });
  }

  Future<void> _maybeOpenQrScanner(IrmaRepository repo, NavigatorState navigator) async {
    // Check if the setting is enabled to open the QR scanner on start up
    final startQrScannerOnStartUp = await repo.preferences.getStartQRScan().first;

    if (startQrScannerOnStartUp) {
      // Check if we actually have permission to use the camera
      final hasCameraPermission = await Permission.camera.isGranted;

      if (hasCameraPermission) {
        // Check if the app was started with a HandleURLEvent or resumed when returning from in-app browser.
        // If so, do not open the QR scanner.
        final appResumedAutomatically = await repo.appResumedAutomatically();
        if (!appResumedAutomatically) {
          navigator.pushNamed(ScannerScreen.routeName);
        }
      } else {
        // If the user has revoked the camera permission, just turn off the setting
        await repo.preferences.setStartQRScan(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We wrap this widget in a WillPopScope to make sure a back press on Android returns the user to the
    // home tab first. If the home tab is already selected, then we cannot go back further. The HomeScreen is the
    // root route in the navigator. In that case, we background the app on Android.
    // On iOS, there is no back button so we don't have to handle this case.
    return WillPopScope(
      onWillPop: () async {
        if (selectedTab == IrmaNavBarTab.home) {
          IrmaRepositoryProvider.of(context).bridgedDispatch(AndroidSendToBackgroundEvent());
        } else {
          setState(() {
            selectedTab = IrmaNavBarTab.home;
          });
        }
        return false;
      },
      child: PendingPointerListener(
        child: Scaffold(
          backgroundColor: IrmaTheme.of(context).backgroundTertiary,
          appBar: IrmaAppBar(
            titleTranslationKey:
                selectedTab == IrmaNavBarTab.home ? 'home_tab.title' : 'home.nav_bar.${selectedTab.name}',
            noLeading: true,
          ),
          body: SafeArea(
            child: Builder(builder: (context) {
              switch (selectedTab) {
                case IrmaNavBarTab.data:
                  return DataTab();
                case IrmaNavBarTab.activity:
                  return ActivityTab();
                case IrmaNavBarTab.more:
                  return MoreTab(
                    onChangeTab: _changeTab,
                  );
                case IrmaNavBarTab.home:
                  return HomeTab(
                    onChangeTab: _changeTab,
                  );
              }
            }),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: const IrmaQrScanButton(
            key: Key('nav_button_scanner'),
          ),
          bottomNavigationBar: IrmaNavBar(
            selectedTab: selectedTab,
            onChangeTab: _changeTab,
          ),
        ),
      ),
    );
  }
}
