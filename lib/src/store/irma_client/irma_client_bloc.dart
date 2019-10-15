import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/plugins/irma_mobile_bridge/events.dart';
import 'package:irmamobile/src/store/irma_client/irma_client_state.dart';

class IrmaClientBloc extends Bloc<Object, IrmaClientState> {
  @override
  IrmaClientState get initialState => IrmaClientState();

  @override
  Stream<IrmaClientState> mapEventToState(
    Object appEvent,
  ) async* {
    if (appEvent is IrmaConfiguration) {
      IrmaConfiguration event = appEvent;
      yield currentState.copyWith(
        schemeManagers: Map.from(currentState.schemeManagers)..addAll(event.schemeManagers),
        issuers: Map.from(currentState.issuers)..addAll(event.issuers),
        credentialTypes: Map.from(currentState.credentialTypes)..addAll(event.credentialTypes),
      );
    } else if (appEvent is CredentialsEvent) {
      CredentialsEvent event = appEvent;

      Map credentials = Map.from(currentState.credentials);
      event.credentials.forEach((credential) => credentials[credential.hash] = credential);

      yield currentState.copyWith(
        credentials: credentials,
      );
    }
  }
}
