import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_repository_provider.dart';

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

  void _onClose(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: IrmaAppBar(
          titleTranslationKey: 'Session helper',
          leadingAction: () => _onClose(context),
          leadingIcon: Icon(Icons.arrow_back, semanticLabel: FlutterI18n.translate(context, 'accessibility.back')),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => IrmaRepositoryProvider.of(context).startTestSession(_controller.text),
            ),
          ],
        ),
        body: TextField(
          controller: _controller,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          expands: true,
        ),
      );
}
