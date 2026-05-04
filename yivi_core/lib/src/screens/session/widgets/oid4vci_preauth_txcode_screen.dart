import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:pinput/pinput.dart";

import "../../../models/schemaless/credential_store.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../util/language.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/translated_text.dart";
import "session_scaffold.dart";

class OpenId4VciPreAuthTxCodeScreen extends StatefulWidget {
  final List<schemaless.CredentialDescriptor> issuedCredentials;
  final PreAuthorizationCodeTransactionCodeParameters transactionCodeParameters;
  final void Function(String code) onSubmit;
  final VoidCallback onDismiss;

  const OpenId4VciPreAuthTxCodeScreen({
    super.key,
    required this.issuedCredentials,
    required this.transactionCodeParameters,
    required this.onSubmit,
    required this.onDismiss,
  });

  @override
  State<OpenId4VciPreAuthTxCodeScreen> createState() =>
      _OpenId4VciPreAuthTxCodeScreenState();
}

class _OpenId4VciPreAuthTxCodeScreenState
    extends State<OpenId4VciPreAuthTxCodeScreen> {
  final _focusNode = FocusNode();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool get _isNumeric => widget.transactionCodeParameters.inputMode == "numeric";

  TextInputType get _keyboardType =>
      _isNumeric ? TextInputType.number : TextInputType.text;

  List<TextInputFormatter> get _inputFormatters =>
      _isNumeric ? [FilteringTextInputFormatter.digitsOnly] : const [];

  String _bodyKey() {
    return widget.issuedCredentials.length > 1
        ? "issuance.pre-authorized_code.tx_code_screen.body_multiple"
        : "issuance.pre-authorized_code.tx_code_screen.body";
  }

  Map<String, String> _bodyParams(BuildContext context) {
    final issuer = getTranslation(
      context,
      widget.issuedCredentials.first.issuer.name,
    );
    if (widget.issuedCredentials.length > 1) {
      return {
        "issuer": issuer,
        "count": widget.issuedCredentials.length.toString(),
      };
    }
    return {
      "issuer": issuer,
      "credential": getTranslation(
        context,
        widget.issuedCredentials.first.name,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final length = widget.transactionCodeParameters.length;

    return SessionScaffold(
      appBarTitle: "issuance.pre-authorized_code.tx_code_screen.title",
      onDismiss: widget.onDismiss,
      bottomNavigationBar: _buildBottomBar(context, length),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: theme.defaultSpacing),
                TranslatedText(
                  "issuance.pre-authorized_code.tx_code_screen.header",
                  isHeader: true,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: theme.neutralExtraDark,
                  ),
                ),
                SizedBox(height: theme.defaultSpacing),
                TranslatedText(
                  _bodyKey(),
                  translationParams: _bodyParams(context),
                ),
                if (widget.transactionCodeParameters.description != null) ...[
                  SizedBox(height: theme.smallSpacing),
                  Text(
                    widget.transactionCodeParameters.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.neutral,
                    ),
                  ),
                ],
                SizedBox(height: theme.largeSpacing),
                _buildInput(context, length),
                SizedBox(height: theme.largeSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context, int? length) {
    final theme = IrmaTheme.of(context);

    if (length != null) {
      final defaultPinTheme = PinTheme(
        width: 50,
        height: 50,
        textStyle: TextStyle(
          fontSize: 25,
          color: Color.fromRGBO(30, 60, 87, 1),
          fontWeight: FontWeight.w600,
        ),
        decoration: BoxDecoration(
          color: theme.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
        ),
      );

      final focusedPinTheme = defaultPinTheme.copyWith(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: theme.surfaceSecondary,
          border: Border.all(color: theme.link),
          borderRadius: BorderRadius.circular(10),
        ),
      );

      return Pinput(
        controller: _textController,
        key: const Key("oid4vci_tx_code_input_field"),
        focusNode: _focusNode,
        autofocus: true,
        keyboardType: _keyboardType,
        inputFormatters: _inputFormatters,
        mainAxisAlignment: MainAxisAlignment.start,
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: focusedPinTheme,
        length: length,
        onCompleted: widget.onSubmit,
        pinAnimationType: PinAnimationType.scale,
        hapticFeedbackType: HapticFeedbackType.lightImpact,
      );
    }

    return TextField(
      controller: _textController,
      key: const Key("oid4vci_tx_code_input_field"),
      focusNode: _focusNode,
      autocorrect: false,
      autofocus: true,
      textAlign: TextAlign.center,
      keyboardType: _keyboardType,
      inputFormatters: _inputFormatters,
      onChanged: (_) => setState(() {}),
      onSubmitted: (value) {
        if (value.isNotEmpty) widget.onSubmit(value);
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, int? length) {
    final cancelLabel = FlutterI18n.translate(
      context,
      "issuance.pre-authorized_code.tx_code_screen.cancel",
    );

    if (length != null) {
      return IrmaBottomBar(
        secondaryButtonLabel: cancelLabel,
        onSecondaryPressed: widget.onDismiss,
      );
    }

    final continueLabel = FlutterI18n.translate(
      context,
      "issuance.pre-authorized_code.tx_code_screen.continue",
    );
    return IrmaBottomBar(
      primaryButtonLabel: continueLabel,
      onPrimaryPressed: _textController.text.isNotEmpty
          ? () => widget.onSubmit(_textController.text)
          : null,
      secondaryButtonLabel: cancelLabel,
      onSecondaryPressed: widget.onDismiss,
    );
  }
}
