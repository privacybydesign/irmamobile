import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../data/irma_repository.dart";
import "../../models/credential_store.dart";
import "../../providers/email_linking_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/session_launcher.dart";
import "../../routing/navigation.dart";
import "add_data_sheet.dart";
import "secure_app.dart";

/// The e-mail type of the default keyshare scheme in the credential store
/// (its issue URL names the issuer); null when the store has none.
Future<CredentialDescriptor?> keyshareEmailType(IrmaRepository repo) async {
  final credentialId = "${repo.defaultKeyshareScheme}.sidn-pbdf.email";
  final store = await repo.getCredentialStoreItems().first;
  return store
      .where((item) => item.credential.credentialId == credentialId)
      .firstOrNull
      ?.credential;
}

/// Opens linking, from the banner, the settings or the link in the e-mail:
/// the Add data sheet on the keyshare scheme's e-mail type, at its address
/// step with its details underneath. A link already received moves it on to
/// the code. Errors go to the error screen.
Future<void> openEmailLinking(BuildContext context) async {
  final repo = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(irmaRepositoryProvider);
  final CredentialDescriptor type;
  try {
    final found = await keyshareEmailType(repo);
    final issueUrl = found?.issueURL;
    if (found == null || issueUrl == null || issueUrl.isEmpty) {
      throw UnsupportedError(
        "The keyshare e-mail type has no suitable issue url",
      );
    }
    type = found;
  } catch (e) {
    if (context.mounted) {
      context.pushErrorScreen(message: "error linking e-mail address: $e");
    }
    return;
  }
  if (!context.mounted) return;
  await showAddDataSheet(
    context,
    addNew: type,
    flyToDataTab: false,
    linking: true,
  );
}

/// Pushes the disclosure that shares the new address with the keyshare
/// server, once the linking sheet has added it and gone. Issuance and
/// keyshare registration stay two sessions: the keyshare server never
/// issues. [context] outlives the sheet (the root navigator's).
///
/// [prefer] is the hash of the e-mail card to share, picked on the share
/// screen when it opens (an address already in the app, chosen before).
Future<void> shareEmailWithKeyshare(
  BuildContext context, {
  String? prefer,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final linking = container.read(emailLinkingProvider.notifier);

  try {
    final pointer = await linking.startDisclosure();
    if (!context.mounted) return;

    final outcome = container.read(sessionLauncherProvider).handle(pointer);
    if (outcome case SessionStarted(:final sessionId)) {
      linking.trackDisclosure(sessionId);
      if (prefer != null) preferCardInSession(container, sessionId, prefer);
    }
  } catch (e) {
    if (!context.mounted) return;
    context.pushErrorScreen(message: "error linking e-mail address: $e");
  }
}
