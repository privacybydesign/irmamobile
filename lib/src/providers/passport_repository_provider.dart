import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vcmrtd/vcmrtd.dart';

import '../data/passport_reader.dart';

final passportReaderProvider = StateNotifierProvider.autoDispose<PassportReader, PassportReadingState>((ref) {
  final r = PassportReader(NfcProvider());

  // when the widget is no longer used, we want to cancel the reader
  ref.onDispose(r.cancel);
  return r;
});

final passportUrlProvider = StateProvider((ref) => '');
