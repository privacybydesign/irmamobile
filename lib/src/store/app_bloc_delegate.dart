import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/plugins/irma_mobile_bridge/events.dart';
import 'package:irmamobile/src/plugins/irma_mobile_bridge/irma_mobile_bridge_plugin.dart';

class AppBlocDelegate extends BlocDelegate {
  List<Bloc> _appBlocs = [];
  Object _lastEvent;

  // Maintain a registry of global blocs that can be statically dispatched,
  // mainly from the IrmaMobileBridge plugin. Widgets should use BlocBuilder instead.
  Bloc registerBloc(Bloc bloc) {
    _appBlocs.add(bloc);
    return bloc;
  }

  // Intercept any event that is sent to any bloc, and dispatch it to global blocs
  @override
  void onEvent(Bloc originatingBloc, Object event) {
    super.onEvent(originatingBloc, event);

    // Check if we already handled this event (TODO: this is very ugly, will fix)
    if (event == _lastEvent) return;
    _lastEvent = event;

    // Send the event to every bloc exchep
    _appBlocs.forEach((appBloc) {
      if (originatingBloc != appBloc) {
        appBloc.dispatch(event);
      }
    });

    // If the event is bridgable, send it to the bridge
    if (event is BridgeableEvent) {
      IrmaMobileBridgePlugin().dispatch(event);
    }
  }
}
