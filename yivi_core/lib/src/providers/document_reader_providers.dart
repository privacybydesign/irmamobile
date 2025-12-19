import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:vcmrtd/internal.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../models/mrz.dart";

final idCardReaderProvider = StateNotifierProvider.autoDispose
    .family<
      DocumentReader<PassportData>,
      DocumentReaderState,
      ScannedIdCardMrz
    >((ref, mrz) {
      final nfc = NfcProvider();

      // ID-cards are always PACE
      final accessKey = DBAKey(
        mrz.documentNumber,
        mrz.dateOfBirth,
        mrz.dateOfExpiry,
        paceMode: true,
      );

      final dgReader = DataGroupReader(
        nfc,
        DF1.PassportAID,
        paceAccessKey: accessKey,
      );

      // ID-cards have the exact same data groups as passports, so we'll just use the same parser
      final parser = PassportParser();
      final docReader = DocumentReader(
        documentParser: parser,
        dataGroupReader: dgReader,
        nfc: nfc,
        config: DocumentReaderConfig(readIfAvailable: {.dg1, .dg2, .dg15}),
      );

      ref.onDispose(docReader.cancel);
      return docReader;
    });

final passportReaderProvider = StateNotifierProvider.autoDispose
    .family<
      DocumentReader<PassportData>,
      DocumentReaderState,
      ScannedPassportMrz
    >((ref, mrz) {
      final nfc = NfcProvider();
      final bacAccessKey = DBAKey(
        mrz.documentNumber,
        mrz.dateOfBirth,
        mrz.dateOfExpiry,
      );

      final paceAccessKey = DBAKey(
        mrz.documentNumber,
        mrz.dateOfBirth,
        mrz.dateOfExpiry,
        paceMode: true,
      );

      final dgReader = DataGroupReader(
        nfc,
        DF1.PassportAID,
        bacAccessKey: bacAccessKey,
        paceAccessKey: paceAccessKey,
      );
      final parser = PassportParser();
      final docReader = DocumentReader(
        documentParser: parser,
        dataGroupReader: dgReader,
        nfc: nfc,
        config: DocumentReaderConfig(readIfAvailable: {.dg1, .dg2, .dg15}),
      );

      ref.onDispose(docReader.cancel);
      return docReader;
    });

final drivingLicenceReaderProvider = StateNotifierProvider.autoDispose
    .family<
      DocumentReader<DrivingLicenceData>,
      DocumentReaderState,
      ScannedDrivingLicenceMrz
    >((ref, mrz) {
      final nfc = NfcProvider();
      final AccessKey accessKey;
      final bool enableBac;
      if (mrz.version == "1") {
        accessKey = BapKey(
          "${mrz.configuration}${mrz.countryCode}${mrz.version}${mrz.documentNumber}${mrz.randomData}",
        );
        enableBac = true;
      } else {
        accessKey = CanKey(mrz.documentNumber, .drivingLicence);
        enableBac = false;
      }

      final dgReader = DataGroupReader(
        nfc,
        DF1.DriverAID,
        bacAccessKey: enableBac ? accessKey : null,
        paceAccessKey: accessKey,
      );
      final parser = DrivingLicenceParser(failDg1CategoriesGracefully: true);
      final docReader = DocumentReader(
        documentParser: parser,
        dataGroupReader: dgReader,
        nfc: nfc,
        config: DocumentReaderConfig(
          // Skipping DG5 due to bad signature image quality
          readIfAvailable: {.dg1, .dg6, .dg11, .dg12, .dg13},
        ),
      );

      ref.onDispose(docReader.cancel);
      return docReader;
    });
