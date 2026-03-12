import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../models/schemaless/credential_store.dart";
import "../../theme/theme.dart";
import "../../util/language.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_close_button.dart";
import "widgets/schemaless_add_data_questions.dart";

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
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    final paddingText = EdgeInsets.fromLTRB(
      theme.defaultSpacing,
      theme.tinySpacing,
      theme.defaultSpacing,
      0,
    );
    final paddingQuestions = EdgeInsets.fromLTRB(
      theme.smallSpacing,
      theme.mediumSpacing,
      theme.smallSpacing,
      0,
    );

    final text = (widget.faq?.intro.isEmpty ?? false)
        ?
          // Fallback generic add credential text
          FlutterI18n.translate(
            context,
            "data.add.details.obtain",
            translationParams: {
              "credential": widget.credential.name.translate(lang),
            },
          )
        : getTranslation(context, widget.faq!.intro).replaceAll("\\n", "\n");

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: "data.add.details.title",
        leading: YiviBackButton(
          onTap: widget.inDisclosure ? widget.onCancel : null,
        ),
        actions: [
          if (widget.onDismiss != null)
            Padding(
              padding: .only(right: theme.defaultSpacing),
              child: IrmaCloseButton(onTap: widget.onDismiss),
            ),
        ],
      ),
      body: SizedBox(
        height: .infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _controller,
          padding: .symmetric(
            vertical: theme.defaultSpacing,
            horizontal: theme.smallSpacing,
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: .start,
              crossAxisAlignment: .start,
              children: [
                Padding(
                  padding: paddingText,
                  child: Text(text, style: theme.textTheme.bodyMedium),
                ),
                if (widget.faq != null)
                  Padding(
                    padding: paddingQuestions,
                    child: SchemalessAddDataQuestions(
                      faq: widget.faq!,
                      inDisclosure: widget.inDisclosure,
                      parentScrollController: _controller,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "data.add.details.get_button",
        onPrimaryPressed: widget.onAdd,
        secondaryButtonLabel: "data.add.details.back_button",
        onSecondaryPressed: widget.onCancel,
        alignment: .horizontal,
      ),
    );
  }
}
