import "package:material_ui/material_ui.dart";

import "../../../models/irma_configuration.dart";
import "../../../models/scheme_events.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";
import "../../../widgets/glass/glass_group.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/irma_app_bar.dart";
import "../util/snackbar.dart";

class RequestorSchemeDetailScreen extends StatelessWidget {
  final RequestorScheme requestorScheme;

  const RequestorSchemeDetailScreen({super.key, required this.requestorScheme});

  void _onDeleteScheme(BuildContext context) {
    repositoryOf(context).bridgedDispatch(RemoveRequestorSchemeEvent(schemeId: requestorScheme.id));
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
      appBar: IrmaAppBar(
        titleString: requestorScheme.id,
        actions: [
          PlainIconButton(
            icon: Icons.delete_outline_rounded,
            danger: true,
            semanticsLabel: "Delete",
            onPressed: () => _onDeleteScheme(context),
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
