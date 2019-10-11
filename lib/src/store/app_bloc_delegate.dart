import 'package:bloc/bloc.dart';
import 'package:irmamobile/src/plugins/irma_mobile_bridge/events.dart';
import 'package:irmamobile/src/plugins/irma_mobile_bridge/irma_mobile_bridge_plugin.dart';

class AppBlocDelegate extends BlocDelegate {
  List<Bloc> _appBlocs = [];

  // Maintain a registry of global blocs that can be statically dispatched,
  // mainly from the IrmaMobileBridge plugin. Widgets should use BlocBuilder instead.
  Bloc registerBloc(Bloc bloc) {
    _appBlocs.add(bloc);
    return bloc;
  }

  // Intercept any event that is sent to any bloc, and dispatch it to global blocs
  // If the event is bridgable, send it to the bridge
  @override
  void onEvent(Bloc originatingBloc, Object event) {
    super.onEvent(originatingBloc, event);

    _appBlocs.forEach((appBloc) {
      if (originatingBloc != appBloc) {
        appBloc.dispatch(event);
      }
    });

    if (event is BridgeableEvent) {
      IrmaMobileBridgePlugin().dispatch(event);
    }
  }
}
