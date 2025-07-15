import 'package:flutter/material.dart';

import '../../../providers/irma_repository_provider.dart';
import '../../../widgets/irma_app_bar.dart';

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
    appBar: IrmaAppBar(
      titleTranslationKey: 'debug.session_helper',
      actions: [
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () => IrmaRepositoryProvider.of(context).startTestSession(_controller.text),
        ),
      ],
    ),
    body: SafeArea(
      child: TextField(controller: _controller, keyboardType: TextInputType.multiline, maxLines: null, expands: true),
    ),
  );
}
