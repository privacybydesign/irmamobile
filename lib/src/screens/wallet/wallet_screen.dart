// This code is not null safe yet.
// @dart=2.11

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/screens/add_cards/card_store_screen.dart';
import 'package:irmamobile/src/screens/debug/debug_screen.dart';
import 'package:irmamobile/src/screens/help/help_screen.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/wallet/models/wallet_bloc.dart';
import 'package:irmamobile/src/screens/wallet/models/wallet_events.dart';
import 'package:irmamobile/src/screens/wallet/models/wallet_state.dart' as walletblocstate;
import 'package:irmamobile/src/screens/wallet/widgets/wallet.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet_drawer.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class WalletScreen extends StatelessWidget {
  static const routeName = "/wallet";

  @override
  Widget build(BuildContext context) {
    final WalletBloc bloc = WalletBloc();

    return BlocProvider<WalletBloc>.value(value: bloc, child: _WalletScreen(bloc: bloc));
  }
}

class _WalletScreen extends StatefulWidget {
  final WalletBloc bloc;

  const _WalletScreen({this.bloc}) : super();

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<_WalletScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<WalletState> _walletKey = GlobalKey<WalletState>();
  final IrmaRepository _irmaClient = IrmaRepository.get();

  StreamSubscription _lockListenerSubscription;
  bool isWalletLocked = true;

  void qrScannerPressed() {
    Navigator.pushNamed(context, ScannerScreen.routeName);
  }

  void helpPressed() {
    Navigator.pushNamed(context, HelpScreen.routeName);
  }

  void addCardsPressed() {
    Navigator.pushNamed(context, CardStoreScreen.routeName);
  }

  void onDebugPressed() {
    Navigator.pushNamed(context, DebugScreen.routeName);
  }

  void onNewCardAnimationShown() {
    widget.bloc.add(NewCardAnitmationShown());
  }

  @override
  void initState() {
    super.initState();
    _lockListenerSubscription = _irmaClient.getLocked().listen((isLocked) {
      // Change wallet state only when lock state changes
      if (isWalletLocked != isLocked) {
        setState(() {
          isWalletLocked = isLocked;
        });
      }
    });
  }

  @override
  void dispose() {
    _lockListenerSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          _walletKey.currentState.androidBackPressed();
          return false;
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: IrmaAppBar(
            title: Text(FlutterI18n.translate(context, 'wallet.title')),
            leadingIcon: Icon(
              IrmaIcons.menu,
              semanticLabel: FlutterI18n.translate(context, "accessibility.menu"),
              size: 20.0,
              key: const Key('open_menu_icon'),
            ),
            leadingAction: () {
              _scaffoldKey.currentState.openDrawer();
            },
            actions: <Widget>[
              if (kDebugMode) ...[
                IconButton(
                  icon: Icon(Icons.videogame_asset),
                  onPressed: onDebugPressed,
                )
              ],
              IconButton(
                icon: Icon(
                  IrmaIcons.lock,
                  size: 20,
                  semanticLabel: FlutterI18n.translate(context, "wallet.lock"),
                  key: const Key('menu_logout_icon'),
                ),
                onPressed: () {
                  IrmaRepository.get().lock();
                },
              ),
            ],
          ),
          drawer: WalletDrawer(),
          body: BlocBuilder<WalletBloc, walletblocstate.WalletState>(
            bloc: widget.bloc,
            key: const Key('wallet_screen'),
            builder: (context, state) {
              if (state.credentials == null) {
                return Container(height: 0);
              }

              final credentialList = state.credentials.values.toList();
              credentialList.sort((a, b) {
                // sort() is not stable when two elements are equal according to the sorting function,
                // but that doesn't matter, because if two credentials are completely identical,
                // irmago keeps only one of them.
                if (a.signedOn != b.signedOn) return a.signedOn.compareTo(b.signedOn);
                if (a.info.fullId != b.info.fullId) return a.info.fullId.compareTo(b.info.fullId);
                return a.attributes.values.join('').compareTo(b.attributes.values.join(''));
              });
              final newCardIndex = state.newCardHash != null
                  ? credentialList.indexWhere((element) => element.hash == state.newCardHash)
                  : 0;
              return Wallet(
                key: _walletKey,
                credentials: credentialList,
                hasLoginLogoutAnimation: true,
                isOpen: !isWalletLocked,
                newCardIndex: newCardIndex,
                showNewCardAnimation: state.showNewCardAnimation,
                onQRScannerPressed: qrScannerPressed,
                onHelpPressed: helpPressed,
                onAddCardsPressed: addCardsPressed,
                onNewCardAnimationShown: onNewCardAnimationShown,
              );
            },
          ),
        ));
  }
}
