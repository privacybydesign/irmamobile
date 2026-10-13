import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/local_backends_provider.dart";
import "../../../providers/preferences_provider.dart";

/// Points the app at a backend setup on a developer's machine. With
/// `adb reverse` for its ports the host is "localhost"; otherwise the
/// machine's address on the local network.
class LocalBackendsTile extends ConsumerWidget {
  const LocalBackendsTile({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final current = ref.read(localBackendsProvider)?.host ?? "";

    final host = await showDialog<String>(
      context: context,
      builder: (context) => _HostDialog(initialHost: current),
    );

    if (host != null) {
      await ref.read(preferencesProvider).setLocalBackendHost(host);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backends = ref.watch(localBackendsProvider);

    return ListTile(
      key: const Key("local_backends_tile"),
      leading: const Icon(Icons.dns_outlined),
      title: const Text("Local backends"),
      subtitle: Text(
        backends == null
            ? "Off"
            : "E-mail issuer ${backends.emailIssuer}\n"
                  "E-mail link ${backends.keyshareEmailLink}",
      ),
      onTap: () => _edit(context, ref),
    );
  }
}

// Owns the controller so it is disposed after the dialog has animated out.
class _HostDialog extends StatefulWidget {
  final String initialHost;

  const _HostDialog({required this.initialHost});

  @override
  State<_HostDialog> createState() => _HostDialogState();
}

class _HostDialogState extends State<_HostDialog> {
  late final _controller = TextEditingController(text: widget.initialHost);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Local backends"),
      content: TextField(
        key: const Key("local_backend_host_field"),
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: "Host",
          hintText: "localhost",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(""),
          child: const Text("Off"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text("Save"),
        ),
      ],
    );
  }
}
