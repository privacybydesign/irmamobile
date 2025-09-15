import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vcmrtd/extensions.dart';
import 'package:vcmrtd/vcmrtd.dart';

import '../models/nfc_reading_state.dart';
import '../models/passport_data_group_config.dart';
import '../models/passport_data_result.dart';
import '../models/passport_mrtd_data.dart';

// ===============================================================
// all the different states the passport reader can be in

class PassportReadingState {}

class PassportReadingPending extends PassportReadingState {}

class PassportReadingCancelled extends PassportReadingState {}

class PassportReadingCancelling extends PassportReadingState {}

class PassportReadingComplete extends PassportReadingState {
  PassportReadingComplete(this.result);
  final PassportDataResult result;
}

class PassportReadingInProgress extends PassportReadingState {
  PassportReadingInProgress({required this.progress, required this.nfcState, required this.message});
  final double progress;
  final NFCReadingState nfcState;
  final String message;
}

class PassportReadingFailed extends PassportReadingState {
  PassportReadingFailed({required this.error});
  final String error;
}

class PassportReadingSuccess extends PassportReadingState {
  PassportReadingSuccess({required this.result});
  final PassportDataResult result;
}

// ===============================================================

class PassportReader extends StateNotifier<PassportReadingState> {
  final NfcProvider _nfc;
  bool _isCancelled = false;

  PassportReader(this._nfc) : super(PassportReadingPending());

  Future<void> cancel() async {
    _isCancelled = true;
    state = PassportReadingCancelling();
    await _disconnect('passport.nfc.cancelling');
    state = PassportReadingCancelled();
  }

  Future<void> readWithMRZ({
    required String documentNumber,
    required DateTime birthDate,
    required DateTime expiryDate,
    required String? countryCode,
    required String sessionId,
    required Uint8List nonce,
  }) async {
    final isPaceCandidate = countryCode != null && paceCountriesAlpha3.contains(countryCode.toUpperCase());

    final key = DBAKey(documentNumber, birthDate, expiryDate, paceMode: isPaceCandidate);

    try {
      await _readAttempt(
        accessKey: key,
        isPace: isPaceCandidate,
        sessionId: sessionId,
        nonce: nonce,
      );
      return;
    } catch (e) {
      if (_isCancelled) return;
      if (isPaceCandidate) {
        // Retry with BAC when PACE fails
        try {
          final key = DBAKey(documentNumber, birthDate, expiryDate, paceMode: false);
          await _readAttempt(
            accessKey: key,
            isPace: false,
            sessionId: sessionId,
            nonce: nonce,
          );
          return;
        } on Exception catch (e2) {
          if (!_isCancelled) {
            _handleError(e2);
          }
        }
      } else if (!_isCancelled) {
        _handleError(e);
      }
    }
  }

  Future<void> _readAttempt({
    required AccessKey accessKey,
    required bool isPace,
    String? sessionId,
    Uint8List? nonce,
  }) async {
    state = PassportReadingInProgress(
      progress: 0.0,
      nfcState: NFCReadingState.waiting,
      message: 'passport.nfc.hold_near_photo_page',
    );

    if (_isCancelled) return;
    await _nfc.connect(iosAlertMessage: 'passport.nfc.hold_near_photo_page');

    if (_isCancelled) {
      await _disconnect('passport.nfc.cancelled');
      state = PassportReadingCancelled();
      return;
    }

    final passport = Passport(_nfc);
    state = PassportReadingInProgress(
      progress: 0.0,
      nfcState: NFCReadingState.connecting,
      message: 'passport.nfc.connecting',
    );

    try {
      await _perform(passport, accessKey, isPace, sessionId: sessionId, nonce: nonce);
    } finally {
      await _disconnect(null);
    }
  }

  static const Set<String> paceCountriesAlpha3 = {
    'AUT', 'BEL', 'BGR', 'HRV', 'CYP', 'CZE', 'DNK', 'EST', 'FIN', 'FRA', 'DEU', 'GRC',
    'HUN', 'IRL', 'ITA', 'LVA', 'LTU', 'LUX', 'MLT', 'NLD', 'POL', 'PRT', 'ROU', 'SVK',
    'SVN', 'ESP', 'SWE', // EU 27
    'ISL', 'LIE', 'NOR', // EEA
    'CHE', // Switzerland
    'GBR', // Great Britain
  };

  Future<void> _perform(
    Passport passport,
    AccessKey accessKey,
    bool isPace, {
    String? sessionId,
    Uint8List? nonce,
  }) async {
    final mrtdData = MrtdData();
    mrtdData.isPACE = isPace;
    mrtdData.isDBA = accessKey is DBAKey && (accessKey.PACE_REF_KEY_TAG == 0x01);

    state = PassportReadingInProgress(
      progress: 0.0,
      nfcState: NFCReadingState.reading,
      message: 'passport.nfc.reading_card_access',
    );

    try {
      mrtdData.cardAccess = await passport.readEfCardAccess();
    } on PassportError {
      debugPrint('Failed to read EF.CardAccess');
    }

    state = PassportReadingInProgress(
      progress: 0.0,
      nfcState: NFCReadingState.reading,
      message: 'passport.nfc.reading_card_security',
    );

    try {
      mrtdData.cardSecurity = await passport.readEfCardSecurity();
    } on PassportError {
      debugPrint('Failed to read EF.CardSecurity');
    }

    state = PassportReadingInProgress(
      progress: 0.0,
      nfcState: NFCReadingState.authenticating,
      message: 'passport.nfc.authenticating',
    );

    if (isPace) {
      await passport.startSessionPACE(accessKey, mrtdData.cardAccess!);
    } else {
      await passport.startSession(accessKey as DBAKey);
    }

    state = PassportReadingInProgress(
      progress: 0.1,
      nfcState: NFCReadingState.authenticating,
      message: 'passport.nfc.authenticating',
    );

    final result = await _readDataGroups(passport, mrtdData, sessionId: sessionId, nonce: nonce);

    state = PassportReadingSuccess(result: result);
  }

  Future<PassportDataResult> _readDataGroups(
    Passport passport,
    MrtdData mrtdData, {
    String? sessionId,
    Uint8List? nonce,
  }) async {
    state = PassportReadingInProgress(
      progress: 0.1,
      nfcState: NFCReadingState.reading,
      message: 'passport.nfc.reading_passport_data',
    );

    try {
      mrtdData.com = await passport.readEfCOM();

      final Map<String, String> dataGroups = {};
      double current = 0.2;

      final configs = _createConfigs(mrtdData);

      for (final cfg in configs) {
        if (_isCancelled) {
          state = PassportReadingCancelling();
          await _disconnect('passport.nfc.cancelled_by_user');

          state = PassportReadingCancelled();
          throw Exception('Cancelled');
        }

        if (mrtdData.com!.dgTags.contains(cfg.tag)) {
          try {
            final dgData = await cfg.readFunction(passport);
            // Convert data group to hex string
            final hexData = dgData.toBytes().hex();
            if (hexData.isNotEmpty) {
              dataGroups[cfg.name] = hexData;
            }
          } catch (e) {
            debugPrint('Failed to read ${cfg.name}: $e');
          }
        }

        state = PassportReadingInProgress(
          progress: current,
          nfcState: NFCReadingState.reading,
          message: 'passport.nfc.reading_passport_data',
        );
      }

      if (sessionId != null && nonce != null && mrtdData.com!.dgTags.contains(EfDG15.TAG)) {
        state = PassportReadingInProgress(
          progress: 0.9,
          nfcState: NFCReadingState.authenticating,
          message: 'passport.nfc.performing_security_verification',
        );

        try {
          mrtdData.dg15 = await passport.readEfDG15();
          if (mrtdData.dg15 != null) {
            final hex = mrtdData.dg15!.toBytes().hex();
            if (hex.isNotEmpty) {
              dataGroups['DG15'] = hex;
            }
          }

          mrtdData.aaSig = await passport.activeAuthenticate(nonce);
        } catch (e) {
          debugPrint('Failed to read DG15 or perform AA: $e');
        }
      }

      mrtdData.sod = await passport.readEfSOD();
      final efSodHex = mrtdData.sod?.toBytes().hex() ?? '';

      state = PassportReadingInProgress(
        progress: 1.0,
        nfcState: NFCReadingState.reading,
        message: 'passport.nfc.completed_successfully',
      );

      return PassportDataResult(
        dataGroups: dataGroups,
        efSod: efSodHex,
        nonce: nonce,
        sessionId: sessionId,
        aaSignature: mrtdData.aaSig,
      );
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(Object e) {
    final se = e.toString().toLowerCase();
    String msg = 'passport.nfc.error_generic';

    if (e is PassportError) {
      if (se.contains('security status not satisfied')) {
        msg = 'passport.nfc.failed_initiate_session';
      }
      debugPrint('PassportError: ${e.message}');
    } else {
      debugPrint('Exception while reading Passport: $e');
    }

    if (se.contains('timeout')) {
      msg = 'passport.nfc.timeout_waiting_for_tag';
    } else if (se.contains('tag was lost')) {
      msg = 'passport.nfc.tag_lost_try_again';
    } else if (se.contains('invalidated by user')) {
      msg = '';
    }

    state = PassportReadingFailed(error: msg);
  }

  Future<void> _disconnect(String? msg) async {
    try {
      if (msg != null && msg.isNotEmpty) {
        await _nfc.disconnect(iosErrorMessage: msg);
      } else {
        await _nfc.disconnect();
      }
    } catch (e) {
      debugPrint('Error during NFC disconnect: $e');
    }
  }

  List<DataGroupConfig> _createConfigs(MrtdData mrtdData) {
    return [
      DataGroupConfig(
        tag: EfDG1.TAG,
        name: 'DG1',
        progressStage: 0.2,
        readFunction: (p) async => mrtdData.dg1 = await p.readEfDG1(),
      ),
      DataGroupConfig(
        tag: EfDG2.TAG,
        name: 'DG2',
        progressStage: 0.5,
        readFunction: (p) async => mrtdData.dg2 = await p.readEfDG2(),
      ),
      DataGroupConfig(
        tag: EfDG5.TAG,
        name: 'DG5',
        progressStage: 0.6,
        readFunction: (p) async => mrtdData.dg5 = await p.readEfDG5(),
      ),
      DataGroupConfig(
        tag: EfDG6.TAG,
        name: 'DG6',
        progressStage: 0.7,
        readFunction: (p) async => mrtdData.dg6 = await p.readEfDG6(),
      ),
      DataGroupConfig(
        tag: EfDG7.TAG,
        name: 'DG7',
        progressStage: 0.7,
        readFunction: (p) async => mrtdData.dg7 = await p.readEfDG7(),
      ),
      DataGroupConfig(
        tag: EfDG8.TAG,
        name: 'DG8',
        progressStage: 0.7,
        readFunction: (p) async => mrtdData.dg8 = await p.readEfDG8(),
      ),
      DataGroupConfig(
        tag: EfDG9.TAG,
        name: 'DG9',
        progressStage: 0.7,
        readFunction: (p) async => mrtdData.dg9 = await p.readEfDG9(),
      ),
      DataGroupConfig(
        tag: EfDG10.TAG,
        name: 'DG10',
        progressStage: 0.7,
        readFunction: (p) async => mrtdData.dg10 = await p.readEfDG10(),
      ),
      DataGroupConfig(
        tag: EfDG11.TAG,
        name: 'DG11',
        progressStage: 0.75,
        readFunction: (p) async => mrtdData.dg11 = await p.readEfDG11(),
      ),
      DataGroupConfig(
        tag: EfDG12.TAG,
        name: 'DG12',
        progressStage: 0.75,
        readFunction: (p) async => mrtdData.dg12 = await p.readEfDG12(),
      ),
      DataGroupConfig(
        tag: EfDG13.TAG,
        name: 'DG13',
        progressStage: 0.8,
        readFunction: (p) async => mrtdData.dg13 = await p.readEfDG13(),
      ),
      DataGroupConfig(
        tag: EfDG14.TAG,
        name: 'DG14',
        progressStage: 0.8,
        readFunction: (p) async => mrtdData.dg14 = await p.readEfDG14(),
      ),
      DataGroupConfig(
        tag: EfDG16.TAG,
        name: 'DG16',
        progressStage: 0.8,
        readFunction: (p) async => mrtdData.dg16 = await p.readEfDG16(),
      ),
    ];
  }
}
