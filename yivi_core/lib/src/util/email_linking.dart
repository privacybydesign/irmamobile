import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../providers/email_linking_provider.dart";
import "../providers/irma_repository_provider.dart";
import "handle_pointer.dart";
import "navigation.dart";

/// Opens the e-mail linking flow, from the banner or from the settings.
Future<void> openEmailLinking(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(irmaRepositoryProvider).startEmailLinking(context, ref);
  } catch (e) {
    if (!context.mounted) return;
    context.pushErrorScreen(message: "error linking e-mail address: $e");
  }
}

/// Replaces the finished e-mail issuance session with the disclosure that
/// shares the new address with the keyshare server. Issuance and keyshare
/// registration stay two sessions: the keyshare server never issues.
Future<void> shareEmailWithKeyshare(BuildContext context, WidgetRef ref) async {
  final linking = ref.read(emailLinkingProvider.notifier);

  try {
    final pointer = await linking.startDisclosure();
    if (!context.mounted) return;

    final sessionId = await handlePointer(
      context,
      pointer,
      pushReplacement: true,
    );
    if (sessionId != null) linking.trackDisclosure(sessionId);
  } catch (e) {
    if (!context.mounted) return;
    context.pushReplacementErrorScreen(
      message: "error linking e-mail address: $e",
    );
  }
}
