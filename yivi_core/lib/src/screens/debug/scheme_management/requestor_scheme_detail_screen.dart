import "package:material_ui/material_ui.dart";

import "../../../models/scheme_events.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";
import "../../../widgets/bars/app_bar.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/surfaces/glass_group.dart";
import "../debug_schemes.dart";
import "../util/snackbar.dart";

class RequestorSchemeDetailScreen extends StatelessWidget {
  final DebugRequestorScheme requestorScheme;

  const RequestorSchemeDetailScreen({super.key, required this.requestorScheme});

  void _onDeleteScheme(BuildContext context) {
    repositoryOf(
      context,
    ).bridgedDispatch(RemoveRequestorSchemeEvent(schemeId: requestorScheme.id));
    Navigator.of(context).pop();

    if (!context.mounted) return;
    showSnackbar(
      context,
      context.tr("debug.scheme_management.remove", {
        "scheme": requestorScheme.id,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: YiviPalette.of(context).background,
      appBar: YiviAppBar(
        titleString: requestorScheme.id,
        actions: [
          YiviIconButton(
            icon: Icons.delete_outline_rounded,
            danger: true,
            label: "Delete",
            onTap: () => _onDeleteScheme(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(YiviSpace.pageSide),
        child: SafeArea(
          child: GlassGroup(
            children: [
              ListTile(
                title: const Text("Type"),
                subtitle: Text(
                  requestorScheme.demo
                      ? "Demo requestor scheme"
                      : "Production requestor scheme",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
