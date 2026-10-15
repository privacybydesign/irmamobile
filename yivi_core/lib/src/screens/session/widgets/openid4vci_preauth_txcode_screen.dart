import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/session_state_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/pill_text_field.dart";
import "../../embedded_issuance_flows/widgets/contact_widgets.dart";
import "session_scaffold.dart";

class OpenID4VCIPreAuthTxCodeScreen extends ConsumerStatefulWidget {
  final int sessionId;
  final List<schemaless.CredentialDescriptor> issuedCredentials;
  final PreAuthorizationCodeTransactionCodeParameters transactionCodeParameters;
  final void Function(String code) onSubmit;
  final VoidCallback onDismiss;

  const OpenID4VCIPreAuthTxCodeScreen({
    super.key,
    required this.sessionId,
    required this.issuedCredentials,
    required this.transactionCodeParameters,
    required this.onSubmit,
    required this.onDismiss,
  });

  @override
  ConsumerState<OpenID4VCIPreAuthTxCodeScreen> createState() =>
      _OpenID4VCIPreAuthTxCodeScreenState();
}

class _OpenID4VCIPreAuthTxCodeScreenState
    extends ConsumerState<OpenID4VCIPreAuthTxCodeScreen> {
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
    final issuer = widget.issuedCredentials.first.issuer.name;

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
        text: widget.issuedCredentials.first.name,
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
    final bodyTemplate =
        widget.transactionCodeParameters.description ??
        FlutterI18n.translate(
          context,
          widget.issuedCredentials.length > 1
              ? "issuance.pre-authorized_code.tx_code_screen.body_multiple"
              : "issuance.pre-authorized_code.tx_code_screen.body",
        );

    final palette = YiviPalette.of(context);
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Semantics(
                  header: true,
                  child: Text(
                    _getTextReplacements(headerTemplate, context),
                    style: palette
                        .display(22, weight: FontWeight.w700)
                        .copyWith(height: 30 / 22, color: palette.heading),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text(
                  _getTextReplacements(bodyTemplate, context),
                  style: palette.body(16).copyWith(height: 24 / 16),
                ),
              ),
              _buildInput(context, length, codeInvalid),
              if (codeInvalid)
                FieldError(
                  FlutterI18n.plural(
                    context,
                    "issuance.pre-authorized_code.tx_code_screen.invalid_code_error",
                    remainingAttempts,
                  ),
                  align: length != null ? TextAlign.center : TextAlign.start,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context, int? length, bool codeInvalid) {
    const labelKey = "issuance.pre-authorized_code.tx_code_screen.label";

    // A known length: a box per character, sent once all are in.
    if (length != null) {
      return ContactCodeField(
        fieldKey: const Key("openid4vci_tx_code_input_field"),
        controller: _textController,
        focusNode: _focusNode,
        length: length,
        invalid: codeInvalid,
        labelKey: labelKey,
        keyboardType: _keyboardType,
        inputFormatters: _inputFormatters,
        onCompleted: widget.onSubmit,
      );
    }

    // Any length: one wide field, sent with Continue.
    final palette = YiviPalette.of(context);
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: color, width: 1.5),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ContactFieldLabel(labelKey),
        TextField(
          controller: _textController,
          key: const Key("openid4vci_tx_code_input_field"),
          focusNode: _focusNode,
          autocorrect: false,
          autofocus: true,
          keyboardType: _keyboardType,
          inputFormatters: _inputFormatters,
          cursorColor: palette.link,
          style: palette
              .display(26)
              .copyWith(letterSpacing: 26 * 0.4, color: palette.heading),
          decoration: InputDecoration(
            filled: true,
            fillColor: palette.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            enabledBorder: border(
              codeInvalid ? palette.danger : palette.outline,
            ),
            focusedBorder: border(codeInvalid ? palette.danger : palette.link),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (value) {
            if (value.isNotEmpty) widget.onSubmit(value);
          },
        ),
      ],
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
