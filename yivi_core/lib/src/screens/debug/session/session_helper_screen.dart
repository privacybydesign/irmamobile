import "package:material_ui/material_ui.dart";

import "../../../providers/irma_repository_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_group.dart";
import "../../../widgets/irma_app_bar.dart";

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
    appBar: IrmaAppBar(
      titleTranslationKey: "debug.session_helper",
      actions: [
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () => IrmaRepositoryProvider.of(
            context,
          ).startTestSession(_controller.text),
        ),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: GlassGroup(
          children: [
            SizedBox(
              height: 480,
              child: Padding(
                padding: const EdgeInsets.all(12),
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
