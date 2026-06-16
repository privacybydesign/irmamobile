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
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    final paddingText = EdgeInsets.fromLTRB(
      context.yivi.spacing.base,
      context.yivi.spacing.tiny,
      context.yivi.spacing.base,
      0,
    );
    final paddingQuestions = EdgeInsets.fromLTRB(
      context.yivi.spacing.small,
      context.yivi.spacing.medium,
      context.yivi.spacing.small,
      0,
    );

    final text = (widget.faq == null || widget.faq!.intro.isEmpty)
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
      backgroundColor: context.colors.surfaceContainerHigh,
      appBar: IrmaAppBar(
        titleTranslationKey: "data.add.details.title",
        leading: YiviBackButton(
          onTap: widget.inDisclosure ? widget.onCancel : null,
        ),
        actions: [
          if (widget.onDismiss != null)
            Padding(
              padding: .only(right: context.yivi.spacing.base),
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
            vertical: context.yivi.spacing.base,
            horizontal: context.yivi.spacing.small,
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: .start,
              crossAxisAlignment: .start,
              children: [
                Padding(
                  padding: paddingText,
                  child: Text(text, style: context.text.bodyMedium),
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
