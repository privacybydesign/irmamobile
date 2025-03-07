import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/credentials.dart';
import 'irma_repository_provider.dart';

final credentialsProvider = StreamProvider<Credentials>((ref) async* {
  final repo = ref.watch(irmaRepositoryProvider);
  final credentialsStream = repo.getCredentials();

  await for (final credentials in credentialsStream) {
    yield credentials;
  }
});
