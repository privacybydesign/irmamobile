import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../util/language.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_close_button.dart';
import 'widgets/add_data_questions.dart';

class AddDataDetailsScreen extends StatefulWidget {
  final CredentialType credentialType;
  final VoidCallback onAdd;
  final VoidCallback onCancel;
  final VoidCallback? onDismiss;
  final bool inDisclosure;

  const AddDataDetailsScreen({
    required this.credentialType,
    required this.onAdd,
    required this.onCancel,
    this.onDismiss,
    this.inDisclosure = false,
  });

  @override
  State<AddDataDetailsScreen> createState() => _AddDataDetailsScreenState();
}

class _AddDataDetailsScreenState extends State<AddDataDetailsScreen> {
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

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'data.add.details.title',
        leading: YiviBackButton(onTap: widget.inDisclosure ? widget.onCancel : null),
        actions: [
          if (widget.onDismiss != null)
            Padding(
              padding: EdgeInsets.only(
                right: theme.defaultSpacing,
              ),
              child: IrmaCloseButton(
                onTap: widget.onDismiss,
              ),
            ),
        ],
      ),
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _controller,
          padding: EdgeInsets.symmetric(
            vertical: theme.defaultSpacing,
            horizontal: theme.smallSpacing,
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: paddingText,
                  child: Text(
                    widget.credentialType.faqIntro.isEmpty
                        ?
                        // Fallback generic add credential text
                        FlutterI18n.translate(
                            context,
                            'data.add.details.obtain',
                            translationParams: {
                              'credential': widget.credentialType.name.translate(lang),
                            },
                          )
                        : getTranslation(context, widget.credentialType.faqIntro).replaceAll('\\n', '\n'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Padding(
                  padding: paddingQuestions,
                  child: AddDataQuestions(
                    inDisclosure: widget.inDisclosure,
                    credentialType: widget.credentialType,
                    parentScrollController: _controller,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'data.add.details.get_button',
        onPrimaryPressed: widget.onAdd,
        secondaryButtonLabel: 'data.add.details.back_button',
        onSecondaryPressed: widget.onCancel,
        alignment: IrmaBottomBarAlignment.horizontal,
      ),
    );
  }
}
