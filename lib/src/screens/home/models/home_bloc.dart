import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/screens/home/models/home_state.dart';
import 'package:irmamobile/src/store/irma_client/irma_client_bloc.dart';
import 'package:irmamobile/src/store/irma_client/irma_client_state.dart';

class HomeBloc extends Bloc<Object, HomeState> {
  final HomeState initialState;

  final IrmaClientBloc irmaClientBloc;

  HomeBloc({this.irmaClientBloc}) : initialState = HomeState();

  Stream<List<RichCredential>> get credentials =>
      irmaClientBloc.state.map((IrmaClientState irmaClientState) => irmaClientState.credentials.values
          .map((Credential credential) => RichCredential(irmaConfiguration: irmaClientState.irmaConfiguration, credential: credential))
          .toList());

  @override
  Stream<HomeState> mapEventToState(Object event) async* {}
}
