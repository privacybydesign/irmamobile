// This code is not null safe yet.
// @dart=2.11

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/screens/wallet/models/wallet_events.dart';
import 'package:irmamobile/src/screens/wallet/models/wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  StreamSubscription<Credentials> credentialStreamSubscription;

  WalletBloc() : super(WalletState()) {
    final repo = IrmaRepository.get();
    credentialStreamSubscription = repo.getCredentials().listen((allCredentials) {
      final credentials = allCredentials.rebuiltRemoveWhere((_, c) => c.isKeyshareCredential);
      String newCardHash;
      final newKeyIndexes = _getIndexesOfNewKeys(state.credentials, credentials);
      if (newKeyIndexes.isNotEmpty) {
        newCardHash = credentials.values.elementAt(newKeyIndexes.first).hash;
      }

      add(CredentialUpdate(credentials, newCardHash, showNewCardAnimation: newCardHash != null));
    });
  }

  List<int> _getIndexesOfNewKeys(Credentials previousCredentials, Credentials newCredentials) {
    final List<int> newKeyIndexes = <int>[];
    if (previousCredentials == null || newCredentials == null) {
      return <int>[];
    }

    for (int i = 0; i < newCredentials.keys.length; i++) {
      if (!previousCredentials.containsKey(newCredentials.keys.elementAt(i))) {
        newKeyIndexes.add(i);
      }
    }

    return newKeyIndexes;
  }

  @override
  Future<void> close() async {
    credentialStreamSubscription.cancel();
    return super.close();
  }

  @override
  Stream<WalletState> mapEventToState(WalletEvent event) async* {
    if (event is CredentialUpdate) {
      yield state.copyWith(
          credentials: event.credentials,
          newCardHash: event.newCardHash,
          showNewCardAnimation: event.showNewCardAnimation);
    }

    if (event is NewCardAnitmationShown) {
      yield state.copyWith(showNewCardAnimation: false);
    }
  }
}
