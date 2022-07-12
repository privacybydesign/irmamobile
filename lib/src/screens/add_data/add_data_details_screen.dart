import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/irma_configuration.dart';
import '../../theme/theme.dart';
import '../../util/language.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/irma_repository_provider.dart';
import 'widgets/add_data_questions.dart';

class AddDataDetailsScreen extends StatefulWidget {
  const AddDataDetailsScreen({required this.credentialType});

  final CredentialType credentialType;

  @override
  _AddDataDetailsScreenState createState() => _AddDataDetailsScreenState();
}

class _AddDataDetailsScreenState extends State<AddDataDetailsScreen> {
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
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
      appBar: const IrmaAppBar(
        titleTranslationKey: 'data.add.details.title',
      ),
      body: SingleChildScrollView(
        controller: _controller,
        padding: EdgeInsets.all(theme.tinySpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.credentialType.faqIntro.isNotEmpty)
              Padding(
                padding: paddingText,
                child: Text(
                  getTranslation(context, widget.credentialType.faqIntro).replaceAll('\\n', '\n'),
                  style: theme.textTheme.bodyText2,
                ),
              ),
            Padding(
              padding: paddingQuestions,
              child: AddDataQuestions(
                credentialType: widget.credentialType,
                parentScrollController: _controller,
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'data.add.details.get_button',
        onPrimaryPressed: () => IrmaRepositoryProvider.of(context).openIssueURL(context, widget.credentialType.fullId),
        secondaryButtonLabel: 'data.add.details.back_button',
        onSecondaryPressed: () => Navigator.of(context).pop(),
        alignment: IrmaBottomBarAlignment.horizontal,
      ),
    );
  }
}
