import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:pinput/pinput.dart";

import "../../../models/schemaless/credential_store.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/session_state_provider.dart";
import "../../../theme/theme.dart";
import "../../../util/language.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "session_scaffold.dart";

class OpenId4VciPreAuthTxCodeScreen extends ConsumerStatefulWidget {
  final int sessionId;
  final List<schemaless.CredentialDescriptor> issuedCredentials;
  final PreAuthorizationCodeTransactionCodeParameters transactionCodeParameters;
  final void Function(String code) onSubmit;
  final VoidCallback onDismiss;

  const OpenId4VciPreAuthTxCodeScreen({
    super.key,
    required this.sessionId,
    required this.issuedCredentials,
    required this.transactionCodeParameters,
    required this.onSubmit,
    required this.onDismiss,
  });

  @override
  ConsumerState<OpenId4VciPreAuthTxCodeScreen> createState() =>
      _OpenId4VciPreAuthTxCodeScreenState();
}

class _OpenId4VciPreAuthTxCodeScreenState
    extends ConsumerState<OpenId4VciPreAuthTxCodeScreen> {
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

  bool get _isNumeric =>
      widget.transactionCodeParameters.inputMode == "numeric";

  TextInputType get _keyboardType =>
      _isNumeric ? TextInputType.number : TextInputType.text;

  List<TextInputFormatter> get _inputFormatters =>
      _isNumeric ? [FilteringTextInputFormatter.digitsOnly] : const [];

  String _getTextReplacements(String template, BuildContext context) {
    final issuer = getTranslation(
      context,
      widget.issuedCredentials.first.issuer.name,
    );

    final replacements = <String, ({String text, bool bold})>{
      "{issuer}": (text: issuer, bold: true),
    };
    if (widget.issuedCredentials.length > 1) {
      replacements["{count}"] = (
        text: widget.issuedCredentials.length.toString(),
        bold: false,
      );
    } else {
      replacements["{credential}"] = (
        text: getTranslation(context, widget.issuedCredentials.first.name),
        bold: true,
      );
    }

    for (final entry in replacements.entries) {
      template = template.replaceAll(entry.key, entry.value.text);
    }

    return template;
  }

  @override
  Widget build(BuildContext context) {
    // When a wrong code is submitted the backend reports a new
    // remainingTxCodeAttempts value. Clear the input and refocus so the
    // user can retry. The error styling itself is driven directly off
    // session state below.
    ref.listen(sessionStateProvider(widget.sessionId), (prev, next) {
      final prevAttempts = prev?.value?.remainingTxCodeAttempts;
      final nextAttempts = next.value?.remainingTxCodeAttempts;
      if (nextAttempts != null && nextAttempts != prevAttempts) {
        _textController.clear();
        _focusNode.requestFocus();
      }
    });

    final headerTemplate = FlutterI18n.translate(
          context,
          "issuance.pre-authorized_code.tx_code_screen.header",
        );
    final bodyTemplate = widget.transactionCodeParameters.description ??
        FlutterI18n.translate(
          context,
          widget.issuedCredentials.length > 1 
              ? "issuance.pre-authorized_code.tx_code_screen.body_multiple"
              : "issuance.pre-authorized_code.tx_code_screen.body",
        );

    final theme = IrmaTheme.of(context);
    final length = widget.transactionCodeParameters.length;
    final remainingAttempts = ref
        .watch(sessionStateProvider(widget.sessionId))
        .value
        ?.remainingTxCodeAttempts;
    final codeInvalid = remainingAttempts != null;

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
                Semantics(
                  header: true,
                  child: Text(
                    _getTextReplacements(headerTemplate, context),
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: theme.neutralExtraDark,
                    ),
                  ),
                ),
                SizedBox(height: theme.defaultSpacing),
                Text(
                  _getTextReplacements(bodyTemplate, context),
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: theme.largeSpacing),
                _buildInput(context, length, codeInvalid),
                if (codeInvalid)
                  Text(
                    FlutterI18n.plural(
                      context,
                      "issuance.pre-authorized_code.tx_code_screen.invalid_code_error",
                      remainingAttempts,
                    ),
                    style: TextStyle(color: theme.error),
                  ),
                SizedBox(height: theme.largeSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context, int? length, bool codeInvalid) {
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
          color: codeInvalid
              ? theme.error.withAlpha(40)
              : theme.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
        ),
      );

      final focusedPinTheme = defaultPinTheme.copyWith(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: codeInvalid
              ? theme.error.withAlpha(40)
              : theme.surfaceSecondary,
          border: Border.all(color: codeInvalid ? theme.error : theme.link),
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
      decoration: InputDecoration(
        enabledBorder: codeInvalid
            ? UnderlineInputBorder(borderSide: BorderSide(color: theme.error))
            : null,
        focusedBorder: codeInvalid
            ? UnderlineInputBorder(borderSide: BorderSide(color: theme.error))
            : null,
      ),
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
