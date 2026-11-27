import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/credential_store.dart";
import "../../../models/session_state.dart";
import "../../../providers/session_state_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/after_frame.dart";
import "../../../util/i18n.dart";
import "../../../widgets/bars/action_bar.dart";
import "../../../widgets/input/pill_text_field.dart";
import "../../../widgets/sheet/sheet.dart";
import "../../../widgets/sheet/sheet_actions.dart";
import "../../embedded_issuance_flows/widgets/contact_widgets.dart";
import "../layout/session_scaffold.dart";

class OpenID4VCIPreAuthTxCodeScreen extends ConsumerStatefulWidget {
  final int sessionId;
  final List<CredentialDescriptor> issuedCredentials;
  final PreAuthorizationCodeTransactionCodeParameters transactionCodeParameters;
  final void Function(String code) onSubmit;
  final VoidCallback onDismiss;

  /// A page in a sheet: the sheet's own bar, back declines, and Continue
  /// (for a code of any length) at the bottom.
  final bool inSheet;

  const OpenID4VCIPreAuthTxCodeScreen({
    super.key,
    required this.sessionId,
    required this.issuedCredentials,
    required this.transactionCodeParameters,
    required this.onSubmit,
    required this.onDismiss,
    this.inSheet = false,
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
    afterFrame(_focusNode.requestFocus);
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

    final headerTemplate = context.tr(
      "issuance.pre-authorized_code.tx_code_screen.header",
    );
    final bodyTemplate =
        widget.transactionCodeParameters.description ??
        context.tr(
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

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x4),
          child: Semantics(
            header: true,
            child: Text(
              _getTextReplacements(headerTemplate, context),
              style: palette.titleCompact,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            YiviSpace.x4,
            YiviSpace.x8,
            YiviSpace.x4,
            0,
          ),
          child: Text(
            _getTextReplacements(bodyTemplate, context),
            style: palette.body(16).copyWith(height: 24 / 16),
          ),
        ),
        _buildInput(context, length, codeInvalid),
        if (codeInvalid)
          FieldError(
            context.plural(
              "issuance.pre-authorized_code.tx_code_screen.invalid_code_error",
              remainingAttempts,
            ),
            align: length != null ? TextAlign.center : TextAlign.start,
          ),
      ],
    );

    if (widget.inSheet) {
      final continueLabel = context.tr(
        "issuance.pre-authorized_code.tx_code_screen.continue",
      );
      return SheetPage.scroll(
        key: const Key("sheet_openid4vci_tx_code"),
        title: SheetTitle(
          context.tr("issuance.pre-authorized_code.tx_code_screen.title"),
        ),
        // Left by dragging its header down: no close button.
        exits: SheetExits(onBack: widget.onDismiss, close: SheetClose.none),
        padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
        // A code of a known length is sent once it is complete.
        action: length != null
            ? null
            : SheetAction(
                key: const Key("sheet_openid4vci_tx_code_continue"),
                label: continueLabel,
                onTap: _textController.text.isNotEmpty
                    ? () => widget.onSubmit(_textController.text)
                    : null,
              ),
        child: Padding(
          padding: const EdgeInsets.only(top: YiviSpace.x16),
          child: form,
        ),
      );
    }

    return SessionScaffold(
      appBarTitle: "issuance.pre-authorized_code.tx_code_screen.title",
      onDismiss: widget.onDismiss,
      bottomNavigationBar: _buildBottomBar(context, length),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            YiviSpace.x16,
            YiviSpace.x16,
            YiviSpace.x16,
            YiviSpace.x32,
          ),
          child: form,
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
              vertical: YiviSpace.x16,
            ),
            enabledBorder: pillFieldBorder(
              codeInvalid ? palette.danger : palette.outline,
            ),
            focusedBorder: pillFieldBorder(
              codeInvalid ? palette.danger : palette.link,
            ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (value) {
            if (value.isNotEmpty) widget.onSubmit(value);
          },
        ),
      ],
    );
  }

  /// A code of a known length is sent once it is complete: no button.
  /// Leaving is the close button's.
  Widget? _buildBottomBar(BuildContext context, int? length) {
    if (length != null) return null;
    return ActionBar.single(
      label: context.tr("issuance.pre-authorized_code.tx_code_screen.continue"),
      onTap: _textController.text.isNotEmpty
          ? () => widget.onSubmit(_textController.text)
          : null,
    );
  }
}
