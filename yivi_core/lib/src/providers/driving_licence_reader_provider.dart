import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:vcmrtd/internal.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../yivi_core.dart";

final drivingLicenceReaderProvider = StateNotifierProvider.autoDispose
    .family<
      DocumentReader<DrivingLicenceData>,
      DocumentReaderState,
      ScannedDrivingLicenceMrz
    >((ref, scannedDriverLicenceMRZ) {
      final nfc = NfcProvider();
      final AccessKey accessKey;
      final bool enableBac;

      // A version 1 driving licence has no PACE support, so we use BAP for that
      if (scannedDriverLicenceMRZ.version == "1") {
        accessKey = BapKey(
          "${scannedDriverLicenceMRZ.configuration}${scannedDriverLicenceMRZ.countryCode}${scannedDriverLicenceMRZ.version}${scannedDriverLicenceMRZ.documentNumber}${scannedDriverLicenceMRZ.randomData}",
        );
        enableBac = true;
      } else {
        accessKey = CanKey(
          scannedDriverLicenceMRZ.documentNumber,
          scannedDriverLicenceMRZ.documentType,
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
