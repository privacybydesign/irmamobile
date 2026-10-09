import "package:flutter_riverpod/flutter_riverpod.dart";

import "../data/feature_flags.dart";
import "feature_flag_provider.dart";
import "irma_repository_provider.dart";

/// Where a credential stands in the "data from another website" flow.
enum ExternalIssuerStatus {
  /// Flag off, or the credential is not issued on a website.
  notExternal,

  /// Issued on a website, the user has not opened it yet.
  ready,

  /// The user opened the website and the issuance has not finished.
  waiting,
}

typedef ExternalIssuerKey = ({String credentialId, String? issueUrl});

final externalIssuerFlowEnabledProvider = Provider<bool>(
  (ref) =>
      ref.watch(featureFlagProvider(FeatureFlag.externalIssuerFlow)).value ??
      false,
);

/// Credential ids whose website the user opened and whose issuance session
/// has not finished yet. Lives in memory: it is cleared when a session ends.
final websiteLaunchedCredentialsProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(irmaRepositoryProvider).getInAppLaunchedCredentialTypes(),
);

final externalIssuerStatusProvider =
    Provider.family<ExternalIssuerStatus, ExternalIssuerKey>((ref, key) {
      if (!ref.watch(externalIssuerFlowEnabledProvider)) {
        return ExternalIssuerStatus.notExternal;
      }

      final issueUrl = key.issueUrl;
      final repo = ref.watch(irmaRepositoryProvider);
      if (issueUrl == null ||
          issueUrl.isEmpty ||
          !repo.issuesViaWebsite(key.credentialId)) {
        return ExternalIssuerStatus.notExternal;
      }

      final launched = ref.watch(websiteLaunchedCredentialsProvider).value;
      return launched?.contains(key.credentialId) ?? false
          ? ExternalIssuerStatus.waiting
          : ExternalIssuerStatus.ready;
    });
