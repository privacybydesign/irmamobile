import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/providers/passport_issuer_provider.dart';
import 'package:irmamobile/src/providers/passport_reader_provider.dart';
import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/util/navigation.dart';
import 'package:mrz_parser/mrz_parser.dart';
import 'package:vcmrtd/vcmrtd.dart';

import '../irma_binding.dart';
import '../util.dart';
import 'helpers.dart';
import 'issuance_helpers.dart';

Future<void> navigateToNfcScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding,
  FakePassportReader reader,
  FakePassportIssuer issuer,
) async {
  await pumpAndUnlockApp(
    tester,
    binding.repository,
    null,
    [
      passportReaderProvider.overrideWith((ref) => reader),
      passportIssuerProvider.overrideWithValue(issuer),
    ],
  );

  final homeContext = tester.element(find.byType(HomeScreen));
  homeContext.pushPassportManualEnterScreen();
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('document_nr_input_field')), 'AB1234567');
  await tester.enterText(find.byKey(const Key('passport_dob_field')), '1990-01-01');
  await tester.enterText(find.byKey(const Key('passport_expiry_date_field')), '2030-12-31');

  final continueButton = find.byKey(const Key('bottom_bar_primary'));
  await tester.waitFor(continueButton.hitTestable());
  await tester.tapAndSettle(continueButton);

  await tester.pump(const Duration(seconds: 1));
}

Future<void> openPassportDetailsScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  List<Override> overrides = const [],
}) async {
  await pumpAndUnlockApp(
    tester,
    binding.repository,
    null,
    overrides.isEmpty ? null : overrides,
  );

  final addDataButton = find.byIcon(CupertinoIcons.add_circled_solid);
  await tester.tapAndSettle(addDataButton);

  final passportCredential =
      binding.repository.irmaConfiguration.credentialTypes.values.firstWhere((type) => type.id == 'passport');

  final passportTile = find.byKey(Key('${passportCredential.fullId}_tile'));
  await tester.scrollUntilVisible(
    passportTile,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tapAndSettle(passportTile);

  await tester.waitFor(find.byType(AddDataDetailsScreen));
}

class FakePassportIssuer implements PassportIssuer {
  int startSessionCount = 0;

  @override
  Future<NonceAndSessionId> startSessionAtPassportIssuer() async {
    startSessionCount += 1;
    return NonceAndSessionId(nonce: 'd4e5f6a7d4e5f6a7', sessionId: '4f3c2a1b5e6d7c8f9a0b1c2d3e4f5a6b');
  }

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(PassportDataResult passportDataResult) async {
    final attributes = createMunicipalityPersonalDataAttributes(const Locale('en'));
    final session = await createIssuanceSession(attributes: attributes);
    return IrmaSessionPointer(u: session.u, irmaqr: session.irmaqr);
  }

  @override
  Future<VerificationResponse> verifyPassport(PassportDataResult passportDataResult) {
    throw UnimplementedError();
  }
}

class FakePassportReader extends PassportReader {
  FakePassportReader({
    PassportReaderState? initialState,
    List<PassportReaderState> statesDuringRead = const [],
    this.readDelayCompleter,
    this.onCancelCompleter,
  })  : _initialState = initialState,
        _statesDuringRead = statesDuringRead,
        super(_FakeNfcProvider()) {
    if (_initialState != null) {
      state = _initialState;
    }
  }

  @override
  Future<void> checkNfcAvailability() async {
    await Future.delayed(Duration.zero);
  }

  final PassportReaderState? _initialState;
  final List<PassportReaderState> _statesDuringRead;
  final Completer<void>? readDelayCompleter;
  final Completer<void>? onCancelCompleter;

  bool readCalled = false;
  int readCallCount = 0;
  int cancelCount = 0;
  String? lastDocumentNumber;
  DateTime? lastBirthDate;
  DateTime? lastExpiryDate;
  String? lastCountryCode;

  @override
  Future<(PassportDataResult, MrtdData)?> readWithMRZ({
    required String documentNumber,
    required DateTime birthDate,
    required DateTime expiryDate,
    required String? countryCode,
    required IosNfcMessageMapper iosNfcMessages,
    NonceAndSessionId? activeAuthenticationParams,
  }) async {
    readCalled = true;
    readCallCount += 1;
    lastDocumentNumber = documentNumber;
    lastBirthDate = birthDate;
    lastExpiryDate = expiryDate;
    lastCountryCode = countryCode;

    if (state is PassportReaderNfcUnavailable) {
      return null;
    }

    for (final next in _statesDuringRead) {
      state = next;
      await Future<void>.delayed(Duration(milliseconds: 10));
    }

    if (readDelayCompleter != null) {
      await readDelayCompleter!.future;
    }

    if (state case PassportReaderSuccess()) {
      return (PassportDataResult(dataGroups: {}, efSod: ''), MrtdData());
    }

    return null;
  }

  @override
  Future<void> cancel() async {
    cancelCount += 1;
    state = PassportReaderCancelling();
    await Future<void>.delayed(Duration.zero);
    state = PassportReaderCancelled();
    if (onCancelCompleter != null && !onCancelCompleter!.isCompleted) {
      onCancelCompleter!.complete();
    }
  }
}

class FakeMrzResult implements MRZResult {
  FakeMrzResult({
    required this.documentNumber,
    required this.birthDate,
    required this.expiryDate,
    required this.countryCode,
  });

  @override
  final String documentNumber;

  @override
  final DateTime birthDate;

  @override
  final DateTime expiryDate;

  @override
  final String countryCode;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNfcProvider extends NfcProvider {
  bool _connected = false;

  @override
  Future<void> connect({Duration? timeout, String iosAlertMessage = ''}) async {
    _connected = true;
  }

  @override
  Future<void> disconnect({String? iosAlertMessage, String? iosErrorMessage}) async {
    _connected = false;
  }

  @override
  bool isConnected() => _connected;

  @override
  Future<void> setIosAlertMessage(String message) async {
    // Do nothing.
  }
}
