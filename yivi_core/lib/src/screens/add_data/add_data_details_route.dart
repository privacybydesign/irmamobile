import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/schemaless/credential_store.dart";
import "../../providers/external_issuer_provider.dart";
import "external_issuer_heads_up_screen.dart";

/// The add-data details route. With the external issuer flow on, a credential
/// issued on a website gets [ExternalIssuerHeadsUpScreen] instead of the
/// regular [details] page.
class AddDataDetailsRoute extends ConsumerWidget {
  final CredentialDescriptor credential;
  final Widget details;
  final VoidCallback onBack;
  final Future<void> Function() onOpenWebsite;

  const AddDataDetailsRoute({
    super.key,
    required this.credential,
    required this.details,
    required this.onBack,
    required this.onOpenWebsite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      externalIssuerStatusProvider((
        credentialId: credential.credentialId,
        issueUrl: credential.issueURL,
      )),
    );
    if (status == ExternalIssuerStatus.notExternal) return details;

    return ExternalIssuerHeadsUpScreen(
      credential: credential,
      onBack: onBack,
      onOpenWebsite: onOpenWebsite,
    );
  }
}
