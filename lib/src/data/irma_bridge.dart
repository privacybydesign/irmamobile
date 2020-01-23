import 'package:irmamobile/src/models/event.dart';

abstract class IrmaBridge {
  void dispatch(Event event);
}
