import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../package_name.dart";
import "../../providers/connectivity_provider.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_info_scaffold_body.dart";

/// Shown in place of the PIN screen while the device has no network
/// connection (issue #618). Logging in has to contact the keyshare server, so
/// a PIN entered while offline can only fail — and a quickly-dismissed failure
/// looks exactly like a wrong PIN, leading users to retry a correct PIN over
/// and over. Instead we explain up front that a connection is required and ask
/// the user to check theirs.
///
/// No retry button is needed: the gate ([OfflineGate]) recovers on its own —
/// once connectivity returns, LockGate swaps this back to the PIN screen.
class OfflineLoginScreen extends StatelessWidget {
  const OfflineLoginScreen()
    : super(key: const ValueKey("offline_login_screen"));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(titleString: "", hasBorder: false),
      body: IrmaInfoScaffoldBody(
        imagePath: yiviAsset("error/no_connection_illustration.svg"),
        titleTranslationKey: "pin.offline.title",
        bodyTranslationKey: "pin.offline.explanation",
      ),
    );
  }
}

/// Gates [child] (the PIN screen) behind live connectivity: while the device
/// is offline it shows [OfflineLoginScreen] instead, and swaps back to [child]
/// the moment connectivity returns.
///
/// Kept as its own widget so the offline gate can be widget-tested without
/// standing up the whole LockGate / GoRouter / keyshare stack.
class OfflineGate extends ConsumerWidget {
  final Widget child;

  const OfflineGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Optimistic default: while the first connectivity lookup is still pending
    // we show [child] (the PIN screen) rather than flashing the offline
    // message on cold start.
    final online = ref.watch(isOnlineProvider).value ?? true;
    return online ? child : const OfflineLoginScreen();
  }
}
