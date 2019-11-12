import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/authentication_result.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_event.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_state.dart';

class PinBloc extends Bloc<PinEvent, PinState> {
  PinBloc() {
    IrmaRepository.get().getLocked().listen((isLocked) {
      if (isLocked) {
        dispatch(Locked());
      } else {
        dispatch(Unlocked());
      }
    });
  }

  @override
  PinState get initialState => PinState(
        locked: true,
        unlockInProgress: false,
        pinInvalid: false,
      );

  @override
  Stream<PinState> mapEventToState(PinEvent event) async* {
    if (event is Unlock) {
      yield currentState.copyWith(
        unlockInProgress: true,
        errorMessage: null,
      );

      final authenticationResult = await IrmaRepository.get().unlock(event.pin);

      switch (authenticationResult.runtimeType) {
        case AuthenticationResultFailed:
          final authenticationResultFailed = authenticationResult as AuthenticationResultFailed;
          yield currentState.copyWith(
            unlockInProgress: false,
            pinInvalid: true,
            blockedUntil: DateTime.now().add(Duration(seconds: authenticationResultFailed.blockedDuration)),
            remainingAttempts: authenticationResultFailed.remainingAttempts,
          );
          break;
        case AuthenticationResultError:
          final authenticationResultError = authenticationResult as AuthenticationResultError;
          yield currentState.copyWith(
            unlockInProgress: false,
            errorMessage: authenticationResultError.error,
          );
          break;
        case AuthenticationResultSuccess:
          yield currentState.copyWith(
            locked: false,
            unlockInProgress: false,
          );
          break;
        default:
          throw Exception("Unexpected subtype of AuthenticationResult");
      }
    }

    if (event is Lock) {
      // There is currently no feedback because there is no pro-active locking available in irmago.
      IrmaRepository.get().lock();
      yield currentState.copyWith(
        locked: true,
      );
    }

    if (event is Locked) {
      yield currentState.copyWith(
        locked: true,
        unlockInProgress: false,
        pinInvalid: false,
      );
    }

    if (event is Unlocked) {
      yield currentState.copyWith(
        locked: false,
        unlockInProgress: false,
        pinInvalid: false,
      );
    }
  }
}
