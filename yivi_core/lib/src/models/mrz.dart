import "package:mrz_parser/mrz_parser.dart";
import "package:vcmrtd/vcmrtd.dart";

sealed class ScannedMrz {
  final String documentNumber;
  final String countryCode;
  final DocumentType documentType;

  ScannedMrz({
    required this.documentNumber,
    required this.countryCode,
    required this.documentType,
  });
}

class ScannedPassportMrz extends ScannedMrz {
  final DateTime dateOfBirth;
  final DateTime dateOfExpiry;

  ScannedPassportMrz({
    required super.documentNumber,
    required super.countryCode,
    required this.dateOfBirth,
    required this.dateOfExpiry,
  }) : super(documentType: DocumentType.passport);

  factory ScannedPassportMrz.fromMRZResult(PassportMrzResult mrz) {
    return ScannedPassportMrz(
      documentNumber: mrz.documentNumber,
      countryCode: mrz.countryCode,
      dateOfBirth: mrz.birthDate,
      dateOfExpiry: mrz.expiryDate,
    );
  }

  factory ScannedPassportMrz.fromManualEntry({
    required String documentNumber,
    required DateTime dateOfBirth,
    required DateTime dateOfExpiry,
    String countryCode =
        "", // TODO: Get country code from manual entry screen as well
  }) {
    return ScannedPassportMrz(
      documentNumber: documentNumber,
      countryCode: countryCode,
      dateOfBirth: dateOfBirth,
      dateOfExpiry: dateOfExpiry,
    );
  }
}

class ScannedDrivingLicenceMrz extends ScannedMrz {
  final String version;
  final String randomData;
  final String configuration;

  ScannedDrivingLicenceMrz({
    required super.documentNumber,
    required super.countryCode,
    required this.version,
    required this.randomData,
    required this.configuration,
  }) : super(documentType: DocumentType.driverLicense);

  factory ScannedDrivingLicenceMrz.fromMRZResult(DrivingLicenceMrzResult mrz) {
    return ScannedDrivingLicenceMrz(
      documentNumber: mrz.documentNumber,
      countryCode: mrz.countryCode,
      version: mrz.version,
      randomData: mrz.randomData,
      configuration: mrz.configuration,
    );
  }

  factory ScannedDrivingLicenceMrz.fromManualEntry({
    required String mrzString,
  }) {
    final parsed = DrivingLicenceMrzParser().parse([mrzString]);
    return ScannedDrivingLicenceMrz.fromMRZResult(parsed);
  }
}
