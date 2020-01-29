import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/authentication.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_event.dart';
import 'package:irmamobile/src/screens/pin/bloc/pin_state.dart';
import 'package:irmamobile/src/screens/scanner/scanner_screen.dart';
import 'package:irmamobile/src/screens/settings/settings_screen.dart';
import 'package:irmamobile/src/util/navigator_service.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

class PinBloc extends Bloc<PinEvent, PinState> {
  static final PinBloc _singleton = PinBloc._internal();

  factory PinBloc() {
    return _singleton;
  }

  PinBloc._internal() {
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
      );

      final authenticationEvent = await IrmaRepository.get().unlock(pinEvent.pin);
      if (authenticationEvent is AuthenticationSuccessEvent) {
        final preferences = await StreamingSharedPreferences.instance;
        final startQrScanner = await preferences
            .getBool(
              sharedPrefKeyOpenQRScannerOnLaunch,
              defaultValue: false,
            )
            .first;

        if (startQrScanner) {
          NavigatorService.get().pushNamed(ScannerScreen.routeName);
        }

        yield PinState(
          locked: false,
        );
      } else if (authenticationEvent is AuthenticationFailedEvent) {
        yield PinState(
          pinInvalid: true,
          blockedUntil: DateTime.now().add(Duration(seconds: authenticationEvent.blockedDuration)),
          remainingAttempts: authenticationEvent.remainingAttempts,
        );
      } else if (authenticationEvent is AuthenticationErrorEvent) {
        yield PinState(
          errorMessage: authenticationEvent.error,
        );
      } else {
        throw Exception("Unexpected subtype of AuthenticationResult");
      }
    } else if (pinEvent is Lock) {
      // There is currently no feedback because there is no pro-active locking
      // available in irmago.
      IrmaRepository.get().lock();
      yield PinState();
    } else if (pinEvent is Locked) {
      yield PinState();
    } else if (pinEvent is Unlocked) {
      yield PinState(
        locked: false,
      );
    }
  }
}
