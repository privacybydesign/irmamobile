// passport_repository/lib/src/passport_repository_impl.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vcmrtd/extensions.dart';
import 'package:vcmrtd/vcmrtd.dart';

import '../models/nfc_reading_state.dart';
import '../models/passport_data_group_config.dart';
import '../models/passport_data_result.dart';
import '../models/passport_error_info.dart';
import '../models/passport_mrtd_data.dart';

abstract class PassportListener {
  /// Called when the overall state changes.
  void onStateChanged(NFCReadingState state) {}

  /// Called with a human-friendly status or platform alert text (iOS).
  void onMessage(String message) {}

  /// Called as reading progresses [0.0 - 1.0].
  void onProgress(double value) {}

  /// Called after a single data group is read successfully.
  /// [name] is e.g. "DG1", [hex] is the hex-encoded content.
  void onDataGroupRead(String name, String hex) {}

  /// Called when authentication (PACE/BAC, AA) finishes successfully.
  void onAuthenticated() {}

  /// Called when an error occurs.
  void onError(PassportErrorInfo error) {}

  /// Called at the very end with the full result.
  void onComplete(PassportDataResult result) {}

  /// Called when the operation gets cancelled.
  void onCancelled() {}
}

class PassportRepository {
  final NfcProvider _nfc = NfcProvider();
  bool _isCancelled = false;

  PassportRepository();

  /// Cancel the ongoing read (if any).
  Future<void> cancel() async {
    _isCancelled = true;
    await _disconnect('Cancelling...');
  }

  /// Read using MRZ values. Determines PACE based on country code (NLD => PACE).
  Future<void> readWithMRZ({
    required String documentNumber,
    required DateTime birthDate,
    required DateTime expiryDate,
    String? countryCode,
    String? sessionId,
    Uint8List? nonce,
    PassportListener? listener,
  }) async {
    final paceMode = (countryCode == 'NLD');
    final key = DBAKey(documentNumber, birthDate, expiryDate, paceMode: paceMode);
    await _read(accessKey: key, isPace: paceMode, sessionId: sessionId, nonce: nonce, listener: listener);
  }

  Future<void> _read({
    required AccessKey accessKey,
    required bool isPace,
    String? sessionId,
    Uint8List? nonce,
    PassportListener? listener,
  }) async {
    _isCancelled = false;

    void setState(NFCReadingState s, {String? msg, double? progress}) {
      listener?.onStateChanged(s);
      if (msg != null) listener?.onMessage(msg);
      if (progress != null) listener?.onProgress(progress.clamp(0.0, 1.0));
    }

    try {
      setState(NFCReadingState.waiting, msg: 'Hold your phone near the passport photo page', progress: 0.0);

      if (_isCancelled) return;
      await _nfc.connect(iosAlertMessage: 'Hold your phone near Biometric Passport');

      if (_isCancelled) {
        await _disconnect('Cancelled');
        listener?.onCancelled();
        return;
      }

      final passport = Passport(_nfc);
      setState(NFCReadingState.connecting, msg: 'Connecting to passport...');

      await _perform(passport, accessKey, isPace, sessionId: sessionId, nonce: nonce, listener: listener);
    } on Exception catch (e) {
      if (!_isCancelled) {
        _handleError(e, listener);
      }
    } finally {
      await _disconnect('Finished');
    }
  }

  Future<void> _perform(
    Passport passport,
    AccessKey accessKey,
    bool isPace, {
    String? sessionId,
    Uint8List? nonce,
    PassportListener? listener,
  }) async {
    final mrtdData = MrtdData();
    mrtdData.isPACE = isPace;
    mrtdData.isDBA = accessKey is DBAKey ? (accessKey.PACE_REF_KEY_TAG == 0x01) : false;

    listener?.onMessage('Reading EF.CardAccess ...');
    try {
      mrtdData.cardAccess = await passport.readEfCardAccess();
    } on PassportError {
      // ignore & continue
    }

    listener?.onMessage('Reading EF.CardSecurity ...');
    try {
      mrtdData.cardSecurity = await passport.readEfCardSecurity();
    } on PassportError {
      // ignore & continue
    }

    listener?.onStateChanged(NFCReadingState.authenticating);
    listener?.onMessage('Authenticating with passport...');

    if (isPace) {
      await passport.startSessionPACE(accessKey, mrtdData.cardAccess!);
    } else {
      await passport.startSession(accessKey as DBAKey);
    }

    listener?.onAuthenticated();

    final result = await _readDataGroups(passport, mrtdData, sessionId: sessionId, nonce: nonce, listener: listener);
    listener?.onStateChanged(NFCReadingState.success);
    listener?.onProgress(1.0);
    listener?.onComplete(result);
  }

  Future<PassportDataResult> _readDataGroups(
    Passport passport,
    MrtdData mrtdData, {
    String? sessionId,
    Uint8List? nonce,
    PassportListener? listener,
  }) async {
    listener?.onStateChanged(NFCReadingState.reading);
    listener?.onMessage('Reading passport data...');
    listener?.onProgress(0.1);

    try {
      _nfc.setIosAlertMessage('Reading EF.COM ...');
      mrtdData.com = await passport.readEfCOM();

      final configs = <DataGroupConfig>[
        DataGroupConfig(
          tag: EfDG1.TAG,
          name: 'DG1',
          progressIncrement: 0.1,
          readFunction: (p) async => mrtdData.dg1 = await p.readEfDG1(),
        ),
        DataGroupConfig(
          tag: EfDG2.TAG,
          name: 'DG2',
          progressIncrement: 0.1,
          readFunction: (p) async => mrtdData.dg2 = await p.readEfDG2(),
        ),
        DataGroupConfig(
          tag: EfDG5.TAG,
          name: 'DG5',
          progressIncrement: 0.1,
          readFunction: (p) async => mrtdData.dg5 = await p.readEfDG5(),
        ),
        DataGroupConfig(
          tag: EfDG6.TAG,
          name: 'DG6',
          progressIncrement: 0.05,
          readFunction: (p) async => mrtdData.dg6 = await p.readEfDG6(),
        ),
        DataGroupConfig(
          tag: EfDG7.TAG,
          name: 'DG7',
          progressIncrement: 0.05,
          readFunction: (p) async => mrtdData.dg7 = await p.readEfDG7(),
        ),
        DataGroupConfig(
          tag: EfDG8.TAG,
          name: 'DG8',
          progressIncrement: 0.05,
          readFunction: (p) async => mrtdData.dg8 = await p.readEfDG8(),
        ),
        DataGroupConfig(
          tag: EfDG9.TAG,
          name: 'DG9',
          progressIncrement: 0.05,
          readFunction: (p) async => mrtdData.dg9 = await p.readEfDG9(),
        ),
        DataGroupConfig(
          tag: EfDG10.TAG,
          name: 'DG10',
          progressIncrement: 0.05,
          readFunction: (p) async => mrtdData.dg10 = await p.readEfDG10(),
        ),
        DataGroupConfig(
          tag: EfDG11.TAG,
          name: 'DG11',
          progressIncrement: 0.05,
          readFunction: (p) async => mrtdData.dg11 = await p.readEfDG11(),
        ),
        DataGroupConfig(
          tag: EfDG12.TAG,
          name: 'DG12',
          progressIncrement: 0.05,
          readFunction: (p) async => mrtdData.dg12 = await p.readEfDG12(),
        ),
        DataGroupConfig(
          tag: EfDG13.TAG,
          name: 'DG13',
          progressIncrement: 0.05,
          readFunction: (p) async => mrtdData.dg13 = await p.readEfDG13(),
        ),
        DataGroupConfig(
          tag: EfDG14.TAG,
          name: 'DG14',
          progressIncrement: 0.05,
          readFunction: (p) async => mrtdData.dg14 = await p.readEfDG14(),
        ),
        DataGroupConfig(
          tag: EfDG16.TAG,
          name: 'DG16',
          progressIncrement: 0.05,
          readFunction: (p) async => mrtdData.dg16 = await p.readEfDG16(),
        ),
      ];

      _nfc.setIosAlertMessage('Reading Data Groups');

      final Map<String, String> dataGroups = {};
      double current = 0.2;

      for (final cfg in configs) {
        if (_isCancelled) {
          listener?.onStateChanged(NFCReadingState.cancelling);
          await _disconnect('Cancelled by user');
          listener?.onCancelled();
          throw Exception('Cancelled');
        }

        if (mrtdData.com!.dgTags.contains(cfg.tag)) {
          try {
            final dg = await cfg.readFunction(passport);
            // All DG types from vcmrtd implement toBytes()
            final hex = (dg as dynamic).toBytes().hex();
            if (hex.isNotEmpty) {
              dataGroups[cfg.name] = hex;
              listener?.onDataGroupRead(cfg.name, hex);
            }
          } catch (e) {
            debugPrint('Failed to read ${cfg.name}: $e');
          }
        }

        current += cfg.progressIncrement;
        listener?.onProgress(current.clamp(0.0, 0.9));
      }

      // DG15 + Active Authentication
      if (sessionId != null && nonce != null && mrtdData.com!.dgTags.contains(EfDG15.TAG)) {
        listener?.onMessage('Performing security verification...');
        listener?.onStateChanged(NFCReadingState.authenticating);
        listener?.onProgress(0.9);

        try {
          mrtdData.dg15 = await passport.readEfDG15();
          if (mrtdData.dg15 != null) {
            final hex = mrtdData.dg15!.toBytes().hex();
            if (hex.isNotEmpty) {
              dataGroups['DG15'] = hex;
              listener?.onDataGroupRead('DG15', hex);
            }
          }

          _nfc.setIosAlertMessage('Doing AA ...');
          mrtdData.aaSig = await passport.activeAuthenticate(nonce);
        } catch (e) {
          debugPrint('Failed to read DG15 or perform AA: $e');
        }
      }

      // EF.SOD
      _nfc.setIosAlertMessage('Reading EF.SOD ...');
      mrtdData.sod = await passport.readEfSOD();
      final efSodHex = mrtdData.sod?.toBytes().hex() ?? '';

      listener?.onMessage('Passport reading completed successfully!');
      listener?.onProgress(1.0);

      return PassportDataResult(
        dataGroups: dataGroups,
        efSod: efSodHex,
        nonce: nonce,
        sessionId: sessionId,
        aaSignature: mrtdData.aaSig,
      );
    } catch (e) {
      _handleError(e, listener);
      rethrow;
    }
  }

  void _handleError(Object e, PassportListener? listener) {
    final se = e.toString().toLowerCase();
    String msg = 'An error has occurred while reading Passport!';

    if (e is PassportError) {
      if (se.contains('security status not satisfied')) {
        msg = 'Failed to initiate session with passport. Check input data!';
      }
      debugPrint('PassportError: ${e.message}');
    } else {
      debugPrint('Exception while reading Passport: $e');
    }

    if (se.contains('timeout')) {
      msg = 'Timeout while waiting for Passport tag';
    } else if (se.contains('tag was lost')) {
      msg = 'Tag was lost. Please try again!';
    } else if (se.contains('invalidated by user')) {
      msg = '';
    }

    listener?.onStateChanged(NFCReadingState.error);
    listener?.onMessage(msg);
    listener?.onError(PassportErrorInfo(msg, e));
  }

  Future<void> _disconnect(String msg) async {
    try {
      if (msg.isNotEmpty) {
        await _nfc.disconnect(iosErrorMessage: msg);
      } else {
        await _nfc.disconnect(iosAlertMessage: 'Finished');
      }
    } catch (e) {
      // ignore disconnect errors
    }
  }
}
