import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../data/demo_session_requests.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/preferences_provider.dart";
import "../../widgets/irma_app_bar.dart";
import "util/snackbar.dart";

final _issueDemoInAppProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).getIssueDemoCredentialsInApp(),
);

/// Sessions that walk through the redesign flows without a website: they run
/// on the demo IRMA server and start in the app. A website would hand them
/// back through a link, which another Yivi app on the phone may take.
class TestFlowsScreen extends ConsumerWidget {
  const TestFlowsScreen({super.key});

  /// Starts the session [build] makes from the demo credentials and the ones
  /// the user holds. Without a request, shows [unavailable] instead.
  Future<void> _start(
    BuildContext context,
    WidgetRef ref, {
    required String? Function(DemoSessionRequests requests, Set<String> held)
    build,
    required String unavailable,
    bool issueInApp = false,
  }) async {
    final repo = IrmaRepositoryProvider.of(context);
    final configuration = await repo.getIrmaConfiguration().first;
    final held = (await repo.getSchemalessCredentials().first).credentials
        .map((credential) => credential.credentialId)
        .toSet();
    final request = build(
      DemoSessionRequests.fromConfiguration(configuration),
      held,
    );
    if (request == null) {
      if (context.mounted) showSnackbar(context, unavailable);
      return;
    }
    if (issueInApp) {
      await ref.read(preferencesProvider).setIssueDemoCredentialsInApp(true);
    }
    await repo.startTestSession(request);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issueInApp = ref.watch(_issueDemoInAppProvider).value ?? false;

    return Scaffold(
      appBar: IrmaAppBar(titleString: "Test flows"),
      body: ListView(
        children: [
          SwitchListTile(
            key: const Key("issue_demo_in_app_switch"),
            title: const Text("Get demo credentials in the app"),
            subtitle: const Text(
              "Getting an irma-demo credential issues it here, with made-up "
              "values, instead of opening its website. The missing data flows "
              "turn this on.",
            ),
            value: issueInApp,
            onChanged: (value) => ref
                .read(preferencesProvider)
                .setIssueDemoCredentialsInApp(value),
          ),
          const Divider(),
          ListTile(
            key: const Key("test_flow_missing_several"),
            leading: const Icon(Icons.playlist_add_check),
            title: const Text("Missing data: three credentials"),
            subtitle: const Text(
              "Share three demo credentials you do not have yet.",
            ),
            onTap: () => _start(
              context,
              ref,
              issueInApp: true,
              build: (requests, held) {
                final missing = requests.missing(held, 3);
                return missing.length < 2 ? null : requests.disclosure(missing);
              },
              unavailable:
                  "You hold most demo credentials already. Delete some "
                  "first.",
            ),
          ),
          ListTile(
            key: const Key("test_flow_missing_one"),
            leading: const Icon(Icons.playlist_add),
            title: const Text("Missing data: one credential"),
            subtitle: const Text(
              "Share one demo credential you do not have yet.",
            ),
            onTap: () => _start(
              context,
              ref,
              issueInApp: true,
              build: (requests, held) {
                final missing = requests.missing(held, 1);
                return missing.isEmpty ? null : requests.disclosure(missing);
              },
              unavailable:
                  "You hold all demo credentials already. Delete one first.",
            ),
          ),
          ListTile(
            key: const Key("test_flow_issue_several"),
            leading: const Icon(Icons.library_add),
            title: const Text("Issue three credentials at once"),
            subtitle: const Text(
              "One issuance with three demo credentials, as from a QR code.",
            ),
            onTap: () => _start(
              context,
              ref,
              build: (requests, held) {
                final known = requests.known;
                return known.isEmpty
                    ? null
                    : requests.issuance(known.take(3).toList());
              },
              unavailable: "The demo scheme has none of these credentials.",
            ),
          ),
          ListTile(
            key: const Key("test_flow_share_choice"),
            leading: const Icon(Icons.alt_route),
            title: const Text("Share with a choice"),
            subtitle: const Text(
              "Share one of the demo credentials you hold, so there is a "
              "choice.",
            ),
            onTap: () => _start(
              context,
              ref,
              build: (requests, held) {
                final options = requests.heldOf(held);
                return options.length < 2
                    ? null
                    : requests.choice(options.take(3).toList());
              },
              unavailable:
                  "You need two demo credentials for a choice. Issue three "
                  "credentials at once first.",
            ),
          ),
        ],
      ),
    );
  }
}
