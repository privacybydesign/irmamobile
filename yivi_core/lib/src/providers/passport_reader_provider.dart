import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:vcmrtd/internal.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../models/mrz.dart";

final passportReaderProvider = StateNotifierProvider.autoDispose
    .family<
      DocumentReader<PassportData>,
      DocumentReaderState,
      ScannedPassportMrz
    >((ref, scannedPassportMRZ) {
      final nfc = NfcProvider();
      final accessKey = DBAKey(
        scannedPassportMRZ.documentNumber,
        scannedPassportMRZ.dateOfBirth,
        scannedPassportMRZ.dateOfExpiry,
      );
      final dgReader = DataGroupReader(nfc, DF1.PassportAID, accessKey);
      final parser = PassportParser();
      final docReader = DocumentReader(
        documentParser: parser,
        dataGroupReader: dgReader,
        nfc: nfc,
        config: DocumentReaderConfig(
          readIfAvailable: {DataGroups.dg1, DataGroups.dg2, DataGroups.dg15},
        ),
      );

      ref.onDispose(docReader.cancel);
      return docReader;
    });

final drivingLicenceReaderProvider = StateNotifierProvider.autoDispose
    .family<
      DocumentReader<DrivingLicenceData>,
      DocumentReaderState,
      ScannedDrivingLicenceMrz
    >((ref, scannedDrivingLicenceMrz) {
      final nfc = NfcProvider();
      final AccessKey accessKey;
      final bool enableBac;
      if (scannedDrivingLicenceMrz.version == "1") {
        accessKey = BapKey(
          "${scannedDrivingLicenceMrz.configuration}${scannedDrivingLicenceMrz.countryCode}${scannedDrivingLicenceMrz.version}${scannedDrivingLicenceMrz.documentNumber}${scannedDrivingLicenceMrz.randomData}",
        );
        enableBac = true;
      } else {
        accessKey = CanKey(
          scannedDrivingLicenceMrz.documentNumber,
          scannedDrivingLicenceMrz.documentType,
        );
        enableBac = false;
      }

      final dgReader = DataGroupReader(
        nfc,
        DF1.DriverAID,
        accessKey,
        enableBac: enableBac,
      );
      final parser = DrivingLicenceParser();
      final docReader = DocumentReader(
        documentParser: parser,
        dataGroupReader: dgReader,
        nfc: nfc,
        config: DocumentReaderConfig(
          // Skipping DG5 due to bad signature image quality
          readIfAvailable: {
            DataGroups.dg1,
            DataGroups.dg6,
            DataGroups.dg11,
            DataGroups.dg12,
            DataGroups.dg13,
          },
        ),
      );

      ref.onDispose(docReader.cancel);
      return docReader;
    });
