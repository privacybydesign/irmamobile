import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:vcmrtd/vcmrtd.dart';

import '../../data/passport_repository.dart';
import '../../models/nfc_reading_state.dart';
import '../../models/passport_data_result.dart';
import '../../models/passport_error_info.dart';
import '../../models/session.dart';
import '../../providers/passport_repository_provider.dart';
import '../../theme/theme.dart';
import '../../util/handle_pointer.dart';
import '../../util/nonce_parser.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_linear_progresss_indicator.dart';
import '../../widgets/translated_text.dart';

class NfcReadingScreen extends ConsumerStatefulWidget {
  final String docNumber;
  final DateTime dateOfBirth;
  final DateTime dateOfExpiry;
  final String? countryCode;
  final VoidCallback? onCancel;
  final ValueChanged<PassportDataResult>? onComplete;

  const NfcReadingScreen({
    required this.docNumber,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    this.countryCode,
    this.onCancel,
    this.onComplete,
    super.key,
  });

  @override
  ConsumerState<NfcReadingScreen> createState() => _NfcReadingScreenState();
}

class _NfcReadingScreenState extends ConsumerState<NfcReadingScreen> implements PassportListener {
  late PassportRepository _repo;

  var _isNfcAvailable = true;
  double _progress = 0.0;
  String _stateKey = 'passport.nfc.connecting';
  String _hintKey = 'passport.nfc.hold_near_photo_page';
  String _tipKey = 'passport.nfc.tip_2';

  PassportDataResult? _pendingIssuanceResult;
  bool _issuanceError = false;

  @override
  void initState() {
    super.initState();

    _repo = ref.read(passportRepositoryProvider);

    _initNFCState();
  }

  Future<void> _initNFCState() async {
    bool isNfcAvailable;
    try {
      NfcStatus status = await NfcProvider.nfcStatus;
      isNfcAvailable = status == NfcStatus.enabled;
    } on PlatformException {
      isNfcAvailable = false;
    }

    if (!mounted) return;

    setState(() {
      _isNfcAvailable = isNfcAvailable;
    });

    if (_isNfcAvailable) {
      await _startReading();
    }
  }

  Future<void> _startReading() async {
    _progress = 0.0;
    _stateKey = 'passport.nfc.connecting';
    _hintKey = 'passport.nfc.hold_near_photo_page';
    _tipKey = 'passport.nfc.tip_2';
    _issuanceError = false;
    _pendingIssuanceResult = null;
    setState(() {});

    try {
      final (sessionId, nonce) = await _getPassportIssuanceSession();
      final nonceBytes = stringToUint8List(nonce);

      await _repo.readWithMRZ(
        documentNumber: widget.docNumber,
        birthDate: widget.dateOfBirth,
        expiryDate: widget.dateOfExpiry,
        countryCode: widget.countryCode,
        sessionId: sessionId,
        nonce: nonceBytes,
        listener: this,
      );
    } catch (_) {
      setState(() {
        _progress = 0.0;
        _stateKey = 'passport.nfc.error';
        _hintKey = 'passport.nfc.error_generic';
        _tipKey = 'passport.nfc.tip_3';
        _issuanceError = true;
      });
    }
  }

  @override
  void dispose() {
    _repo.cancel();
    super.dispose();
  }

  @override
  void onStateChanged(NFCReadingState state) {
    switch (state) {
      case NFCReadingState.waiting:
      case NFCReadingState.connecting:
        _stateKey = 'passport.nfc.connecting';
        _tipKey = 'passport.nfc.tip_2';
        break;
      case NFCReadingState.authenticating:
      case NFCReadingState.reading:
        _stateKey = 'passport.nfc.connecting';
        _tipKey = 'passport.nfc.tip_1';
        break;
      case NFCReadingState.error:
        _tipKey = 'passport.nfc.tip_3';
        break;
      case NFCReadingState.cancelling:
        _stateKey = 'passport.nfc.cancelling';
        break;
      case NFCReadingState.success:
        _stateKey = 'passport.nfc.success';
        break;
      case NFCReadingState.idle:
        _stateKey = 'passport.nfc.idle';
        break;
    }
  }

  @override
  void onMessage(String message) {
    setState(() {
      _hintKey = message;
    });
  }

  @override
  void onProgress(double value) {
    setState(() {
      _progress = value.clamp(0.0, 1.0);
    });
  }

  @override
  void onAuthenticated() {}

  @override
  void onError(PassportErrorInfo error) {
    setState(() {
      _progress = 0.0;
      _stateKey = 'passport.nfc.error';
      _hintKey = 'passport.nfc.error';
      _tipKey = 'passport.nfc.tip_3';
      _issuanceError = false;
      _pendingIssuanceResult = null;
    });
  }

  @override
  void onCancelled() {
    widget.onCancel?.call();
  }

  @override
  void onComplete(PassportDataResult result) async {
    _pendingIssuanceResult = result;
    await _startIssuance(result);
  }

  Future<void> _startIssuance(PassportDataResult passportDataResult) async {
    // Create secure data payload
    final payload = passportDataResult.toJson();
    try {
      // Get the signed IRMA JWt from the passport issuer
      final responseBody = await _getIrmaSessionJwt(payload);
      final irmaServerUrlParam = responseBody['irma_server_url'];
      final jwtUrlParam = responseBody['jwt'];

      // Start the session
      final sessionResponseBody =
          await _startIrmaSession(jwtUrlParam, irmaServerUrlParam);
      final sessionPtr = sessionResponseBody['sessionPtr'];

      if (!mounted) return;
      await handlePointer(context, Pointer.fromString(json.encode(sessionPtr)),
          pushReplacement: false);

      if (!mounted) return;
      _pendingIssuanceResult = null;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _progress = 0.0;
        _stateKey = 'passport.nfc.error';
        _hintKey = 'passport.nfc.error_generic';
        _tipKey = 'passport.nfc.tip_3';
      _issuanceError = true;
      });
    }
  }

  void _handleRetry() {
    if (_issuanceError && _pendingIssuanceResult != null) {
      _startIssuance(_pendingIssuanceResult!);
    } else {
      _startReading();
    }
  }

  void _handleCancel() async {
    final shouldCancel = await _showCancelDialog(context);
    if (shouldCancel) {
      _repo.cancel();
      widget.onCancel?.call();
    }
  }

  Future<(String, String)> _getPassportIssuanceSession() async {
    final storeResp = await http.post(Uri.parse('https://passport-issuer.staging.yivi.app/api/start-validation'),
        headers: {'Content-Type': 'application/json'});
    if (storeResp.statusCode != 200) {
      throw Exception('Store failed: ${storeResp.statusCode} ${storeResp.body}');
    }

    var response = json.decode(storeResp.body);
    return (response['session_id'].toString(), response['nonce'].toString());
  }

  Future<dynamic> _getIrmaSessionJwt(Map<String, dynamic> payload) async {
    final String jsonPayload = json.encode(payload);
    final storeResp = await http.post(
      Uri.parse('https://passport-issuer.staging.yivi.app/api/verify-and-issue'),
      headers: {'Content-Type': 'application/json'},
      body: jsonPayload,
    );
    if (storeResp.statusCode != 200) {
      throw Exception('Store failed: ${storeResp.statusCode} ${storeResp.body}');
    }

    return json.decode(storeResp.body);
  }

  Future<dynamic> _startIrmaSession(String jwt, String irmaServerUrl) async {
    // Start the IRMA session
    final response = await http.post(
      Uri.parse('$irmaServerUrl/session'),
      body: jwt,
    );
    if (response.statusCode != 200) {
      throw Exception('Store failed: ${response.statusCode} ${response.body}');
    }

    return json.decode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'passport.nfc.title',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _isNfcAvailable ? theme.success : theme.error,
                      shape: BoxShape.circle,
                    ),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      _isNfcAvailable ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TranslatedText(
                    _isNfcAvailable ? 'passport.nfc.nfc_enabled' : 'passport.nfc.nfc_disabled',
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isNfcAvailable
                      ? _ScanningContent(
                          theme: theme,
                          tipKey: _tipKey,
                          progressPercent:
                              (_progress * 100).clamp(0, 100).toDouble(),
                          statusKey: _stateKey,
                          hintKey: _hintKey,
                          key: ValueKey('scanning-$_tipKey-$_progress'),
                        )
                      : _DisabledContent(
                          theme: theme, key: const ValueKey('disabled'))),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isNfcAvailable
          ? IrmaBottomBar(
              alignment: IrmaBottomBarAlignment.vertical,
              primaryButtonLabel:
                  _stateKey == 'passport.nfc.error' ? 'ui.retry' : null,
              onPrimaryPressed:
                  _stateKey == 'passport.nfc.error' ? _handleRetry : null,
              secondaryButtonLabel: 'ui.cancel',
              onSecondaryPressed: _handleCancel,
            )
          : IrmaBottomBar(
              alignment: IrmaBottomBarAlignment.vertical,
              primaryButtonLabel: 'ui.retry',
              onPrimaryPressed: () {
                _initNFCState();
              },
              secondaryButtonLabel: 'ui.cancel',
              onSecondaryPressed: _handleCancel,
            ),
    );
  }
}

Future<bool> _showCancelDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const TranslatedText('passport.nfc.cancel_dialog.title'),
          content:
              const TranslatedText('passport.nfc.cancel_dialog.explanation'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const TranslatedText('passport.nfc.cancel_dialog.decline'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const TranslatedText('passport.nfc.cancel_dialog.confirm'),
            ),
          ],
        ),
      ) ??
      false;
}

class _DisabledContent extends StatelessWidget {
  const _DisabledContent({required this.theme, super.key});
  final IrmaThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nfc, size: 80, color: theme.error),
            SizedBox(height: theme.largeSpacing),
            TranslatedText(
              'passport.nfc.nfc_disabled_explanation',
              textAlign: TextAlign.center,
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanningContent extends StatelessWidget {
  const _ScanningContent({
    required this.theme,
    required this.tipKey,
    required this.progressPercent,
    required this.statusKey,
    this.hintKey,
    super.key,
  });

  final IrmaThemeData theme;
  final String tipKey;
  final double progressPercent;
  final String statusKey;
  final String? hintKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.nfc, size: 80, color: theme.link),
        SizedBox(height: theme.mediumSpacing),
        TranslatedText(statusKey, style: theme.textTheme.headlineMedium),
        SizedBox(height: theme.smallSpacing),
        TranslatedText(hintKey ?? '', style: theme.textTheme.bodyMedium),
        SizedBox(height: theme.mediumSpacing),
        IrmaLinearProgressIndicator(filledPercentage: progressPercent),
        SizedBox(height: theme.largeSpacing),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SizedBox(
            height: 48,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: TranslatedText(
                tipKey,
                key: ValueKey(tipKey),
                textAlign: TextAlign.center,
                maxLines: 3,
                style: TextStyle(
                  color: theme.secondary,
                  fontSize: 16,
                  height: 1.4,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
