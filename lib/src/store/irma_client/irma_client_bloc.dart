import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/models/credential.dart';
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
        schemeManagers: Map<String, SchemeManager>.from(currentState.schemeManagers)..addAll(event.schemeManagers),
        issuers: Map<String, Issuer>.from(currentState.issuers)..addAll(event.issuers),
        credentialTypes: Map<String, CredentialType>.from(currentState.credentialTypes)..addAll(event.credentialTypes),
        attributeTypes: Map<String, AttributeType>.from(currentState.attributeTypes)..addAll(event.attributeTypes),
      );
    } else if (appEvent is CredentialsEvent) {
      CredentialsEvent event = appEvent;

      Map<String, Credential> credentials = Map<String, Credential>.from(currentState.credentials);
      event.credentials.forEach((credential) => credentials[credential.hash] = credential);

      yield currentState.copyWith(
        credentials: credentials,
      );
    }
  }

  @override
  void onError(Object error, StackTrace stacktrace) {
    super.onError(error, stacktrace);
    print('$error, $stacktrace');
  }
}
