import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class _Haptic {
  final String description;
  final Future<void> Function() function;

  _Haptic(this.description, this.function);
}

class HapticScreen extends StatelessWidget {
  final VoidCallback onBack;

  const HapticScreen({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  _showSnackBar(BuildContext context, String title) {
    final snackBar = SnackBar(
      duration: const Duration(milliseconds: 500),
      content: Text(title),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  final feedbackForTap = 'Feedback.forTap';
  final feedbackForLongPress = 'Feedback.forLongPress';
  final enableFeedback = 'enableFeedback: true';

  @override
  Widget build(BuildContext context) {
    final haptics = [
      _Haptic('heavy impact', HapticFeedback.heavyImpact),
      _Haptic('light impact', HapticFeedback.lightImpact),
      _Haptic('medium impact', HapticFeedback.mediumImpact),
      _Haptic('selection click', HapticFeedback.selectionClick),
      _Haptic('vibrate', HapticFeedback.vibrate),
    ];

    return Scaffold(
      appBar: IrmaAppBar(
        title: 'Haptics',
        leadingCancel: onBack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: Feedback.wrapForTap(() {
                _showSnackBar(context, feedbackForTap);
              }, context),
              child: Text(feedbackForTap),
            ),
            ElevatedButton(
              onPressed: Feedback.wrapForLongPress(() {
                _showSnackBar(context, feedbackForLongPress);
              }, context),
              child: Text(feedbackForLongPress),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(enableFeedback: true),
              onPressed: () => _showSnackBar(context, enableFeedback),
              child: Text(enableFeedback),
            ),
            ...haptics
                .map(
                  (h) => ElevatedButton(
                    style: ElevatedButton.styleFrom(enableFeedback: true),
                    onPressed: () {
                      _showSnackBar(context, h.description);
                      h.function.call();
                    },
                    child: Text(h.description),
                  ),
                )
                .toList(growable: false),
          ]
              .map((w) => SizedBox(
                    width: double.infinity,
                    child: w,
                  ))
              .toList(growable: false),
        ),
      ),
    );
  }
}
