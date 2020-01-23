import 'dart:convert';

import 'package:irmamobile/src/data/irma_bridge.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/data/mock_data.dart';
import 'package:irmamobile/src/models/app_ready_event.dart';
import 'package:irmamobile/src/models/enroll_event.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';

typedef EventUnmarshaller = Event Function(Map<String, dynamic>);

class IrmaMockBridge extends IrmaBridge {
  IrmaMockBridge();

  @override
  void dispatch(Event event) {
    if (event is AppReadyEvent) {
      IrmaRepository.get()
          .dispatch(IrmaConfigurationEvent.fromJson(jsonDecode(irmaConfigurationEventJson) as Map<String, dynamic>));
    } else if (event is EnrollEvent) {
      // For example respond with IrmaRepository.get().dispatch(EnrollmentSuccessEvent(...))
    }
  }
}
