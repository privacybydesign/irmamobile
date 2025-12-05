import "dart:async";
import "dart:typed_data";

import "package:flutter/cupertino.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:vcmrtd/extensions.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";
import "package:yivi_core/src/providers/passport_reader_provider.dart";
import "package:yivi_core/src/screens/add_data/add_data_details_screen.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/util/navigation.dart";
import "package:yivi_core/yivi_core.dart";

import "../irma_binding.dart";
import "../util.dart";
import "helpers.dart";
import "issuance_helpers.dart";

Future<void> navigateToDrivingLicenceNfcReadingScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding,
  FakeDrivingLicenceReader reader,
  FakePassportIssuer issuer,
) async {
  await pumpAndUnlockApp(tester, binding.repository, null, [
    drivingLicenceReaderProvider.overrideWith((ref, mrz) {
      reader.setMrz(mrz);
      return reader;
    }),
    passportIssuerProvider.overrideWithValue(issuer),
  ]);

  final homeContext = tester.element(find.byType(HomeScreen));
  homeContext.pushDrivingLicenceManualEntryScreen();
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key("driving_licence_mrz_input_field")),
    // Fake MRZ found in Dutch EDL spec
    "D1NLD11234567890AG5R98GT5IN2L4",
  );

  final continueButton = find.byKey(const Key("bottom_bar_primary"));
  await tester.waitFor(continueButton.hitTestable());
  await tester.tapAndSettle(continueButton);

  await tester.pump(const Duration(seconds: 1));
}

Future<void> navigateToIdCardNfcReadingScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding,
  FakePassportReader reader,
  FakePassportIssuer issuer,
) async {
  await pumpAndUnlockApp(tester, binding.repository, null, [
    idCardReaderProvider.overrideWith((ref, mrz) {
      reader.setMrz(mrz);
      return reader;
    }),
    passportIssuerProvider.overrideWithValue(issuer),
  ]);

  final homeContext = tester.element(find.byType(HomeScreen));
  homeContext.pushIdCardManualEntryScreen();
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key("document_nr_input_field")),
    "AB1234567",
  );
  await tester.enterText(
    find.byKey(const Key("passport_dob_field")),
    "1990-01-01",
  );
  await tester.enterText(
    find.byKey(const Key("passport_expiry_date_field")),
    "2030-12-31",
  );

  final continueButton = find.byKey(const Key("bottom_bar_primary"));
  await tester.waitFor(continueButton.hitTestable());
  await tester.tapAndSettle(continueButton);

  await tester.pump(const Duration(seconds: 1));
}

Future<void> navigateToPassportNfcReadingScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding,
  FakePassportReader reader,
  FakePassportIssuer issuer,
) async {
  await pumpAndUnlockApp(tester, binding.repository, null, [
    passportReaderProvider.overrideWith((ref, mrz) {
      reader.setMrz(mrz);
      return reader;
    }),
    passportIssuerProvider.overrideWithValue(issuer),
  ]);

  final homeContext = tester.element(find.byType(HomeScreen));
  homeContext.pushPassportManualEntryScreen();
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key("document_nr_input_field")),
    "AB1234567",
  );
  await tester.enterText(
    find.byKey(const Key("passport_dob_field")),
    "1990-01-01",
  );
  await tester.enterText(
    find.byKey(const Key("passport_expiry_date_field")),
    "2030-12-31",
  );

  final continueButton = find.byKey(const Key("bottom_bar_primary"));
  await tester.waitFor(continueButton.hitTestable());
  await tester.tapAndSettle(continueButton);

  await tester.pump(const Duration(seconds: 1));
}

Future<void> openDrivingLicenceDetailsScreen(
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

  final drivingLicenceCredential = binding
      .repository
      .irmaConfiguration
      .credentialTypes
      .values
      .firstWhere((type) => type.id == "drivinglicence");

  final edlTile = find.byKey(Key("${drivingLicenceCredential.fullId}_tile"));
  await tester.scrollUntilVisible(
    edlTile,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tapAndSettle(edlTile);

  await tester.waitFor(find.byType(AddDataDetailsScreen));
}

Future<void> openIdCardDetailsScreen(
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

  final idCardCredential = binding
      .repository
      .irmaConfiguration
      .credentialTypes
      .values
      .firstWhere((type) => type.id == "idcard");

  final idCardTile = find.byKey(Key("${idCardCredential.fullId}_tile"));
  await tester.scrollUntilVisible(
    idCardTile,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tapAndSettle(idCardTile);

  await tester.waitFor(find.byType(AddDataDetailsScreen));
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

  final passportCredential = binding
      .repository
      .irmaConfiguration
      .credentialTypes
      .values
      .firstWhere((type) => type.id == "passport");

  final passportTile = find.byKey(Key("${passportCredential.fullId}_tile"));
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
  final String? errorToThrowOnIssuance;

  FakePassportIssuer({this.errorToThrowOnIssuance});

  @override
  Future<NonceAndSessionId> startSessionAtPassportIssuer() async {
    startSessionCount += 1;
    return NonceAndSessionId(
      nonce: "d4e5f6a7d4e5f6a7",
      sessionId: "4f3c2a1b5e6d7c8f9a0b1c2d3e4f5a6b",
    );
  }

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData passportDataResult,
    DocumentType documentType,
  ) async {
    if (errorToThrowOnIssuance != null) {
      throw Exception(errorToThrowOnIssuance);
    }
    final attributes = createMunicipalityPersonalDataAttributes(
      const Locale("en"),
    );
    final session = await createIssuanceSession(attributes: attributes);
    return IrmaSessionPointer(u: session.u, irmaqr: session.irmaqr);
  }

  @override
  Future<VerificationResponse> verifyPassport(
    RawDocumentData passportDataResult,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<VerificationResponse> verifyDrivingLicence(
    RawDocumentData drivingLicenceDataResult,
  ) {
    throw UnimplementedError();
  }
}

// ====================================================================================

class FakeDrivingLicenceReader extends DocumentReader<DrivingLicenceData> {
  FakeDrivingLicenceReader({
    DocumentReaderState? initialState,
    List<DocumentReaderState> statesDuringRead = const [],
    this.readDelayCompleter,
    this.onCancelCompleter,
  }) : _initialState = initialState,
       _statesDuringRead = statesDuringRead,
       super(
         nfc: _FakeNfcProvider(),
         documentParser: DrivingLicenceParser(),
         config: DocumentReaderConfig(
           readIfAvailable: {DataGroups.dg1, DataGroups.dg2, DataGroups.dg15},
         ),
         dataGroupReader: DataGroupReader(
           _FakeNfcProvider(),
           "".parseHex(),
           DBAKey("", DateTime.now(), DateTime.now()),
         ),
       ) {
    if (_initialState != null) {
      state = _initialState;
    }
  }

  @override
  Future<void> checkNfcAvailability() async {
    await Future.delayed(Duration.zero);
  }

  final DocumentReaderState? _initialState;
  final List<DocumentReaderState> _statesDuringRead;
  final Completer<void>? readDelayCompleter;
  final Completer<void>? onCancelCompleter;

  bool readCalled = false;
  int readCallCount = 0;
  int cancelCount = 0;
  String? lastDocumentNumber;
  String? lastCountryCode;
  String? lastVersion;
  String? lastRandomData;
  String? lastConfiguration;

  void setMrz(ScannedDrivingLicenceMrz mrz) {
    lastCountryCode = mrz.countryCode;
    lastDocumentNumber = mrz.documentNumber;
    lastVersion = mrz.version;
    lastRandomData = mrz.randomData;
    lastConfiguration = mrz.configuration;
  }

  @override
  Future<(DrivingLicenceData, RawDocumentData)?> readDocument({
    required IosNfcMessageMapper iosNfcMessages,
    NonceAndSessionId? activeAuthenticationParams,
  }) async {
    readCalled = true;
    readCallCount += 1;

    if (state is DocumentReaderNfcUnavailable) {
      return null;
    }

    for (final next in _statesDuringRead) {
      state = next;
      await Future<void>.delayed(Duration(milliseconds: 10));
    }

    if (readDelayCompleter != null) {
      await readDelayCompleter!.future;
    }

    if (state case DocumentReaderSuccess()) {
      return (
        _fakeDrivingLicenceData(),
        RawDocumentData(dataGroups: {}, efSod: ""),
      );
    }

    return null;
  }

  @override
  Future<void> cancel() async {
    if (!mounted) {
      return;
    }
    cancelCount += 1;
    state = DocumentReaderCancelling();
    await Future<void>.delayed(Duration.zero);
    state = DocumentReaderCancelled();
    if (onCancelCompleter != null && !onCancelCompleter!.isCompleted) {
      onCancelCompleter!.complete();
    }
  }

  @override
  void reset() {
    if (!mounted) {
      return;
    }
    super.reset();
  }
}

// ====================================================================================

class FakePassportReader extends DocumentReader<PassportData> {
  FakePassportReader({
    DocumentReaderState? initialState,
    List<DocumentReaderState> statesDuringRead = const [],
    this.readDelayCompleter,
    this.onCancelCompleter,
  }) : _initialState = initialState,
       _statesDuringRead = statesDuringRead,
       super(
         nfc: _FakeNfcProvider(),
         documentParser: PassportParser(),
         config: DocumentReaderConfig(
           readIfAvailable: {DataGroups.dg1, DataGroups.dg2, DataGroups.dg15},
         ),
         dataGroupReader: DataGroupReader(
           _FakeNfcProvider(),
           "".parseHex(),
           DBAKey("", DateTime.now(), DateTime.now()),
         ),
       ) {
    if (_initialState != null) {
      state = _initialState;
    }
  }

  @override
  Future<void> checkNfcAvailability() async {
    await Future.delayed(Duration.zero);
  }

  final DocumentReaderState? _initialState;
  final List<DocumentReaderState> _statesDuringRead;
  final Completer<void>? readDelayCompleter;
  final Completer<void>? onCancelCompleter;

  bool readCalled = false;
  int readCallCount = 0;
  int cancelCount = 0;
  String? lastDocumentNumber;
  DateTime? lastBirthDate;
  DateTime? lastExpiryDate;
  String? lastCountryCode;

  void setMrz(ScannedMrz mrz) {
    switch (mrz) {
      case ScannedIdCardMrz():
        lastCountryCode = mrz.countryCode;
        lastExpiryDate = mrz.dateOfExpiry;
        lastBirthDate = mrz.dateOfBirth;
        lastDocumentNumber = mrz.documentNumber;
      case ScannedPassportMrz():
        lastCountryCode = mrz.countryCode;
        lastExpiryDate = mrz.dateOfExpiry;
        lastBirthDate = mrz.dateOfBirth;
        lastDocumentNumber = mrz.documentNumber;
      case ScannedDrivingLicenceMrz():
        throw UnimplementedError();
    }
  }

  @override
  Future<(PassportData, RawDocumentData)?> readDocument({
    required IosNfcMessageMapper iosNfcMessages,
    NonceAndSessionId? activeAuthenticationParams,
  }) async {
    readCalled = true;
    readCallCount += 1;

    if (state is DocumentReaderNfcUnavailable) {
      return null;
    }

    for (final next in _statesDuringRead) {
      state = next;
      await Future<void>.delayed(Duration(milliseconds: 10));
    }

    if (readDelayCompleter != null) {
      await readDelayCompleter!.future;
    }

    if (state case DocumentReaderSuccess()) {
      return (_fakePassportData(), RawDocumentData(dataGroups: {}, efSod: ""));
    }

    return null;
  }

  @override
  Future<void> cancel() async {
    if (!mounted) {
      return;
    }
    cancelCount += 1;
    state = DocumentReaderCancelling();
    await Future<void>.delayed(Duration.zero);
    state = DocumentReaderCancelled();
    if (onCancelCompleter != null && !onCancelCompleter!.isCompleted) {
      onCancelCompleter!.complete();
    }
  }

  @override
  void reset() {
    if (!mounted) {
      return;
    }
    super.reset();
  }
}

class _FakeNfcProvider extends NfcProvider {
  bool _connected = false;

  @override
  Future<void> connect({Duration? timeout, String iosAlertMessage = ""}) async {
    _connected = true;
  }

  @override
  Future<void> disconnect({
    String? iosAlertMessage,
    String? iosErrorMessage,
  }) async {
    _connected = false;
  }

  @override
  bool isConnected() => _connected;

  @override
  Future<void> setIosAlertMessage(String message) async {
    // Do nothing.
  }
}

DrivingLicenceData _fakeDrivingLicenceData() {
  return DrivingLicenceData(
    issuingMemberState: "NLD",
    holderSurname: "Clooney",
    holderOtherName: "George",
    dateOfBirth: "1980-01-10",
    placeOfBirth: "Utrecht",
    dateOfIssue: "2018-10-10",
    dateOfExpiry: "2028-10-10",
    issuingAuthority: "Gemeente Meppel",
    documentNumber: "1234567890",
    photoImageData: Uint8List(0),
    bapInputString: "1234",
    saiType: "1234",
    aaPublicKey: null,
    categories: [],
  );
}

PassportData _fakePassportData() {
  final p = PassportParser();

  final fakeDg1 =
      "615D5F1F5A493C4E4C44584938353933354638363939393939393939303C3C3C3C3C3C3732303831343846313130383236384E4C443C3C3C3C3C3C3C3C3C3C3C3856414E3C4445523C535445454E3C3C4D415249414E4E453C4C4F55495345"
          .parseHex();
  final mrz = p.parseDG1(fakeDg1)!.mrz;
  return PassportData(
    mrz: mrz,
    photoImageData: Uint8List(0),
    photoImageType: .jpeg2000,
    photoImageWidth: 0,
    photoImageHeight: 0,
  );
}
