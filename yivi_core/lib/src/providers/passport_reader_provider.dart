import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:vcmrtd/internal.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../models/mrz.dart";

final passportReaderProvider = StateNotifierProvider.autoDispose
    .family<
      DocumentReader<PassportData>,
      DocumentReaderState,
      ScannedPassportMRZ
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
