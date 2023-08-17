import 'package:flutter/material.dart';

import '../../../widgets/irma_app_bar.dart';
import '../../../widgets/irma_repository_provider.dart';

class SessionHelperScreen extends StatefulWidget {
  final String initialRequest;

  const SessionHelperScreen({
    Key? key,
    required this.initialRequest,
  }) : super(key: key);

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
              onPressed: () => IrmaRepositoryProvider.of(context).startTestSession(
                _controller.text,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            expands: true,
          ),
        ),
      );
}
