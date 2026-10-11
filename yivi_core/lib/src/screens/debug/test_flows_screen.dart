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

final _trustDemoServerSettingProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).getTrustDemoServer(),
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
    bool? trustDemoServer,
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
    final preferences = ref.read(preferencesProvider);
    if (issueInApp) await preferences.setIssueDemoCredentialsInApp(true);
    if (trustDemoServer != null) {
      await preferences.setTrustDemoServer(trustDemoServer);
    }
    await repo.startTestSession(request);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issueInApp = ref.watch(_issueDemoInAppProvider).value ?? false;
    final trustDemo = ref.watch(_trustDemoServerSettingProvider).value ?? false;

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
          SwitchListTile(
            key: const Key("trust_demo_server_switch"),
            title: const Text("Demo server is a party Yivi knows"),
            subtitle: const Text(
              "Sessions of the demo server come from Yivi demo, a "
              "verified party, instead of an unknown one. The sharing flows "
              "below set this.",
            ),
            value: trustDemo,
            onChanged: (value) =>
                ref.read(preferencesProvider).setTrustDemoServer(value),
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
            key: const Key("test_flow_share_trusted"),
            leading: const Icon(Icons.verified_outlined),
            title: const Text("Share with a trusted party"),
            subtitle: const Text(
              "Share a demo credential you hold with a party Yivi knows: "
              "one tap.",
            ),
            onTap: () => _start(
              context,
              ref,
              trustDemoServer: true,
              build: (requests, held) {
                final options = requests.heldOf(held);
                return options.isEmpty
                    ? null
                    : requests.disclosure([options.first]);
              },
              unavailable:
                  "You hold no demo credential. Issue three credentials at "
                  "once first.",
            ),
          ),
          ListTile(
            key: const Key("test_flow_share_bsn_trusted"),
            leading: const Icon(Icons.shield_outlined),
            title: const Text("Share a BSN with a trusted party"),
            subtitle: const Text(
              "Share the demo BSN with a party Yivi knows: the BSN gets its "
              "own check. Without the demo personal data, you get it first.",
            ),
            onTap: () => _start(
              context,
              ref,
              trustDemoServer: true,
              issueInApp: true,
              build: (requests, held) {
                final parts = demoBsnAttributeId.split(".");
                final credentialId = parts.take(3).join(".");
                final known =
                    requests.attributesByCredential[credentialId]?.contains(
                      parts.last,
                    ) ??
                    false;
                return known
                    ? requests.disclosureOfAttributes([demoBsnAttributeId])
                    : null;
              },
              unavailable: "The demo scheme has no BSN.",
            ),
          ),
          ListTile(
            key: const Key("test_flow_share_unknown"),
            leading: const Icon(Icons.help_outline),
            title: const Text("Share with an unknown party"),
            subtitle: const Text(
              "Share a demo credential you hold with a party Yivi does not "
              "know.",
            ),
            onTap: () => _start(
              context,
              ref,
              trustDemoServer: false,
              build: (requests, held) {
                final options = requests.heldOf(held);
                return options.isEmpty
                    ? null
                    : requests.disclosure([options.first]);
              },
              unavailable:
                  "You hold no demo credential. Issue three credentials at "
                  "once first.",
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
