import "dart:math";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../models/schemaless/credential_store.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../theme/yivi_palette.dart";
import "../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../widgets/glass/glass_group.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_close_button.dart";
import "../../widgets/irma_markdown.dart";

class SchemalessAddDataDetailsScreen extends StatefulWidget {
  final CredentialDescriptor credential;
  final Faq? faq;
  final VoidCallback onAdd;
  final VoidCallback onCancel;
  final VoidCallback? onDismiss;
  final bool inDisclosure;

  const SchemalessAddDataDetailsScreen({
    required this.credential,
    required this.onAdd,
    required this.onCancel,
    this.onDismiss,
    this.faq,
    this.inDisclosure = false,
  });

  @override
  State<SchemalessAddDataDetailsScreen> createState() =>
      _AddDataDetailsScreenState();
}

class _AddDataDetailsScreenState extends State<SchemalessAddDataDetailsScreen> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The card the user gets, drawn as an example from the type alone.
  schemaless.Credential get _exampleCard {
    final c = widget.credential;
    return schemaless.Credential(
      credentialId: c.credentialId,
      hash: c.credentialId,
      name: c.name,
      issuer: c.issuer,
      image: c.image,
      credentialInstanceIds: const {},
      batchInstanceCountsRemaining: const {},
      attributes: const [],
      revoked: false,
      revocationSupported: false,
      issueUrl: c.issueURL,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final faq = widget.faq;
    // The store escapes line breaks; in the markdown answers each one starts
    // a paragraph.
    String clean(String? text, {String lineBreak = "\n"}) =>
        (text ?? "").replaceAll("\\n", lineBreak);

    final intro = clean(faq?.intro);
    final purpose = clean(faq?.purpose, lineBreak: "\n\n");
    final content = clean(faq?.content, lineBreak: "\n\n");
    final howTo = clean(faq?.howTo, lineBreak: "\n\n");
    final attributeNames = [
      for (final a in widget.credential.attributes) a.effectiveDisplayName,
    ].where((n) => n.isNotEmpty).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: palette.background,
      appBar: IrmaAppBar(
        titleTranslationKey: "data.add.details.title",
        leading: YiviBackButton(
          onTap: widget.inDisclosure ? widget.onCancel : null,
        ),
        actions: [
          if (widget.onDismiss != null)
            IrmaCloseButton(onTap: widget.onDismiss),
        ],
      ),
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _controller,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _ExampleCard(
                    credential: _exampleCard,
                    width: min(MediaQuery.sizeOf(context).width - 32, 358),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.credential.name,
                    style: palette
                        .display(24, weight: FontWeight.w700)
                        .copyWith(height: 32 / 24),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                  child: Text(
                    FlutterI18n.translate(
                      context,
                      "data.add.by",
                      translationParams: {
                        "issuer": widget.credential.issuer.name,
                      },
                    ),
                    style: palette
                        .body(14)
                        .copyWith(color: palette.secondaryText),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                  child: Text(
                    intro.isNotEmpty
                        ? intro
                        : FlutterI18n.translate(
                            context,
                            "data.add.details.obtain",
                            translationParams: {
                              "credential": widget.credential.name,
                            },
                          ),
                    style: palette.body(16).copyWith(height: 24 / 16),
                  ),
                ),
                if (purpose.isNotEmpty)
                  _AnswerCard(
                    titleKey: "data.add.details.purpose_question",
                    child: IrmaMarkdown(purpose),
                  ),
                if (content.isNotEmpty || attributeNames.isNotEmpty)
                  _AnswerCard(
                    titleKey: "data.add.details.content_question",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (content.isNotEmpty) IrmaMarkdown(content),
                        for (final (i, name) in attributeNames.indexed)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: i == 0 && content.isEmpty
                                  ? null
                                  : Border(
                                      top: BorderSide(color: palette.divider),
                                    ),
                            ),
                            child: Text(
                              name,
                              style: palette
                                  .body(15, weight: FontWeight.w600)
                                  .copyWith(color: palette.heading),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (howTo.isNotEmpty)
                  _AnswerCard(
                    titleKey: "data.add.details.howto_question",
                    child: IrmaMarkdown(howTo),
                  ),
                if (widget.inDisclosure)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: palette.outline,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: palette.link,
                            ),
                          ),
                          Expanded(
                            child: IrmaMarkdown(
                              FlutterI18n.translate(
                                context,
                                "data.add.details.disclosure_info_markdown",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        alignment: IrmaBottomBarAlignment.vertical,
        primaryButtonLabel: "data.add.details.get_button",
        onPrimaryPressed: widget.onAdd,
        secondaryButtonLabel: "data.add.details.back_button",
        onSecondaryPressed: widget.onCancel,
      ),
    );
  }
}

/// The card art of the credential with an "Example" badge on its corner.
class _ExampleCard extends StatelessWidget {
  final schemaless.Credential credential;
  final double width;

  const _ExampleCard({required this.credential, required this.width});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CredentialCardArt(credential: credential, width: width),
          Positioned(
            right: 12,
            top: -10,
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: palette.link,
                shape: const StadiumBorder(),
              ),
              child: Text(
                FlutterI18n.translate(context, "data.add.example"),
                style: palette
                    .body(12, weight: FontWeight.w700)
                    .copyWith(color: palette.surface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One question about the credential with its answer, on a rounded card.
class _AnswerCard extends StatelessWidget {
  final String titleKey;
  final Widget child;

  const _AnswerCard({required this.titleKey, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlassGroup(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    FlutterI18n.translate(context, titleKey),
                    style: palette.display(16),
                  ),
                ),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
