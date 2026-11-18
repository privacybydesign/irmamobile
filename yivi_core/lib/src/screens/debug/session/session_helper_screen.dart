import "package:material_ui/material_ui.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../widgets/bars/app_bar.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/surfaces/glass_group.dart";

class SessionHelperScreen extends StatefulWidget {
  final String initialRequest;

  const SessionHelperScreen({super.key, required this.initialRequest});

  @override
  State<StatefulWidget> createState() => _SessionHelperScreenState();
}

class _SessionHelperScreenState extends State<SessionHelperScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.initialRequest;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    backgroundColor: YiviPalette.of(context).background,
    appBar: YiviAppBar(
      titleTranslationKey: "debug.session_helper",
      actions: [
        YiviIconButton(
          icon: Icons.send_rounded,
          label: "Start session",
          onTap: () => repositoryOf(context).startTestSession(_controller.text),
        ),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          YiviSpace.x16,
          YiviSpace.x8,
          YiviSpace.x16,
          YiviSpace.x16,
        ),
        child: GlassGroup(
          children: [
            SizedBox(
              height: 480,
              child: Padding(
                padding: const EdgeInsets.all(YiviSpace.x12),
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontFamily: "monospace", fontSize: 13),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
