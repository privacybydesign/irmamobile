import "package:flutter_riverpod/flutter_riverpod.dart";

import "irma_repository_provider.dart";

/// Credential ids whose website the user opened and whose issuance session
/// has not finished yet. Lives in memory: it is cleared when a session ends.
final websiteLaunchedCredentialsProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(irmaRepositoryProvider).getInAppLaunchedCredentialTypes(),
);
