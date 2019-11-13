import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/screens/wallet/models/wallet_state.dart';

class WalletBloc extends Bloc<Object, WalletState> {
  @override
  final WalletState initialState;

  WalletBloc() : initialState = WalletState();

  Stream<Credentials> get credentials => IrmaRepository.get().getCredentials();

  @override
  Stream<WalletState> mapEventToState(Object event) async* {}
}
