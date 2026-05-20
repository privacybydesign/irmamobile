import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../theme/theme.dart";
import "../../../util/biometric_auth.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/translated_text.dart";

class BiometricSetupScreen extends StatefulWidget {
  final VoidCallback onEnable;
  final VoidCallback onSkip;
  final VoidCallback onPrevious;

  const BiometricSetupScreen({
    super.key,
    required this.onEnable,
    required this.onSkip,
    required this.onPrevious,
  });

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final BiometricAuth _biometricAuth = BiometricAuth();
  bool _busy = false;

  Future<void> _onEnablePressed() async {
    if (_busy) return;
    setState(() => _busy = true);
    final reason = FlutterI18n.translate(context, "pin.biometric.reason");
    final signInTitle = FlutterI18n.translate(
      context,
      "pin.biometric.android_title",
    );
    final cancel = FlutterI18n.translate(context, "ui.cancel");
    final lockOut = FlutterI18n.translate(context, "pin.biometric.lockout");
    final result = await _biometricAuth.authenticate(
      reason: reason,
      androidSignInTitle: signInTitle,
      androidCancelButton: cancel,
      iosCancelButton: cancel,
      iosLockoutMessage: lockOut,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      widget.onEnable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.all(theme.mediumSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: theme.mediumSpacing),
                      Center(
                        child: Icon(
                          Icons.fingerprint,
                          size: 96,
                          color: theme.primary,
                        ),
                      ),
                      SizedBox(height: theme.mediumSpacing),
                      TranslatedText(
                        "enrollment.biometric.title",
                        style: theme.textTheme.displayLarge,
                        textAlign: TextAlign.start,
                      ),
                      SizedBox(height: theme.mediumSpacing),
                      const TranslatedText(
                        "enrollment.biometric.explanation",
                        textAlign: TextAlign.start,
                      ),
                      SizedBox(height: theme.defaultSpacing),
                      const TranslatedText(
                        "enrollment.biometric.privacy",
                        textAlign: TextAlign.start,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "enrollment.biometric.enable",
        onPrimaryPressed: _busy ? null : _onEnablePressed,
        secondaryButtonLabel: "enrollment.biometric.skip",
        onSecondaryPressed: _busy ? null : widget.onSkip,
      ),
    );
  }
}
