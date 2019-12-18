import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/models/authentication_result.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/log.dart';
import 'package:irmamobile/src/models/preferences.dart';
import 'package:irmamobile/src/models/version_information.dart';

abstract class IrmaClient {
  Stream<Credentials> getCredentials();
  Stream<IrmaConfiguration> getIrmaConfiguration();

  Stream<Credential> getCredential(String id);

  Stream<Map<String, Issuer>> getIssuers();

  Stream<VersionInformation> getVersionInformation();

  Stream<bool> getIsEnrolled();

  Stream<List<Log>> loadLogs(int before, int max);

  Stream<Preferences> getPreferences();

  // set whether crash reporting is turned on.
  void setCrashReportingPreference({@required bool value});

  // set whether the qr scanner is opened on app start
  void setQrScannerOnStartupPreference({@required bool value});

  // Deletes all credentials on the phone.
  void deleteAllCredentials();

// TODO: return a Future with state update for this specific enroll action.
  void enroll({String email, String pin, String language});

  // lock locks the irma user session
  void lock();

  // unlock unlocks the irma user session with given pin, returns true on
  // success.
  Future<AuthenticationResult> unlock(String pin);

  // getLocked returns a stream of lock state changes (boolean; true=locked
  // false=unlocked).
  Stream<bool> getLocked();

  void startSession(String request);
}
