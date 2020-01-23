import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/authentication.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_event.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_state.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/util/navigator_service.dart';

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
  Stream<PinState> mapEventToState(PinEvent pinEvent) async* {
    if (pinEvent is Unlock) {
      yield currentState.copyWith(
        unlockInProgress: true,
        errorMessage: null,
      );

      final authenticationEvent = await IrmaRepository.get().unlock(pinEvent.pin);

      if (authenticationEvent is AuthenticationSuccessEvent) {
        final startQrScanner = await IrmaRepository.get().getPreferences().map((p) => p.qrScannerOnStartup).first;

        if (startQrScanner) {
          NavigatorService.get().pushNamed(ScannerScreen.routeName);
        }

        yield currentState.copyWith(
          locked: false,
          unlockInProgress: false,
        );
      } else if (authenticationEvent is AuthenticationFailedEvent) {
        yield currentState.copyWith(
          unlockInProgress: false,
          pinInvalid: true,
          blockedUntil: DateTime.now().add(Duration(seconds: authenticationEvent.blockedDuration)),
          remainingAttempts: authenticationEvent.remainingAttempts,
        );
      } else if (authenticationEvent is AuthenticationErrorEvent) {
        yield currentState.copyWith(
          unlockInProgress: false,
          errorMessage: authenticationEvent.error,
        );
      }
    } else if (pinEvent is Lock) {
      // There is currently no feedback because there is no pro-active locking available in irmago.
      IrmaRepository.get().lock();
      yield currentState.copyWith(
        locked: true,
      );
    } else if (pinEvent is Locked) {
      yield currentState.copyWith(
        locked: true,
        unlockInProgress: false,
        pinInvalid: false,
      );
    } else if (pinEvent is Unlocked) {
      yield currentState.copyWith(
        locked: false,
        unlockInProgress: false,
        pinInvalid: false,
      );
    }
  }
}
