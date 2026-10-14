import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../providers/local_backends_provider.dart";
import "../../../providers/preferences_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/pill_text_field.dart";
import "../../more/widgets/tiles.dart";

/// Points the app at a backend setup on a developer's machine. With
/// `adb reverse` for its ports the host is "localhost"; otherwise the
/// machine's address on the local network.
class LocalBackendsTile extends ConsumerWidget {
  const LocalBackendsTile({super.key});

  static String backendsSummary(WidgetRef ref) {
    final backends = ref.read(localBackendsProvider);
    return backends == null
        ? "Off"
        : "E-mail issuer ${backends.emailIssuer}\n"
              "E-mail link ${backends.keyshareEmailLink}";
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final current = ref.read(localBackendsProvider)?.host ?? "";
    final controller = TextEditingController(text: current);

    final host = await showDialog<String>(
      context: context,
      builder: (context) => GlassDialog(
        title: "Local backends",
        message: LocalBackendsTile.backendsSummary(ref),
        body: PillTextField(
          fieldKey: const Key("local_backend_host_field"),
          controller: controller,
          autofocus: true,
          label: "Host",
          hint: "localhost",
        ),
        actions: [
          FancyPillButton(
            label: "Save",
            height: 52,
            glow: false,
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          ),
          PillButton(
            label: "Off",
            style: PillStyle.text,
            height: 48,
            onPressed: () => Navigator.of(context).pop(""),
          ),
        ],
      ),
    );
    controller.dispose();

    if (host != null) {
      await ref.read(preferencesProvider).setLocalBackendHost(host);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backends = ref.watch(localBackendsProvider);

    final palette = YiviPalette.of(context);
    return Tile(
      key: const Key("local_backends_tile"),
      isLink: false,
      iconData: Icons.dns_outlined,
      labelTranslationKey: "Local backends",
      onTap: () => _edit(context, ref),
      trailing: Text(
        backends == null ? "Off" : "On",
        style: palette.body(14).copyWith(color: palette.secondaryText),
      ),
    );
  }
}
