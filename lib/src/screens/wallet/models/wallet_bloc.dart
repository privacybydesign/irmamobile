import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/screens/wallet/models/wallet_state.dart';
import 'package:irmamobile/src/store/irma_client/irma_client_bloc.dart';
import 'package:irmamobile/src/store/irma_client/irma_client_state.dart';

class WalletBloc extends Bloc<Object, WalletState> {
  final WalletState initialState;

  final IrmaClientBloc irmaClientBloc;

  WalletBloc({this.irmaClientBloc}) : initialState = WalletState();

  Stream<List<RichCredential>> get credentials =>
      irmaClientBloc.state.map((IrmaClientState irmaClientState) => irmaClientState.credentials.values
          .map((Credential credential) =>
              RichCredential(irmaConfiguration: irmaClientState.irmaConfiguration, credential: credential))
          .toList());

  @override
  Stream<WalletState> mapEventToState(Object event) async* {}
}
