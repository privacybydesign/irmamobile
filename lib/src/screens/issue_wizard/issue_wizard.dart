import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/issue_wizard.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:irmamobile/src/screens/issue_wizard/widgets/progressing_list.dart';
import 'package:irmamobile/src/screens/session/session.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/collapsible_helper.dart';
import 'package:irmamobile/src/widgets/collapsible.dart';
import 'package:irmamobile/src/widgets/heading.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_markdown.dart';
import 'package:irmamobile/src/widgets/logo_banner.dart';

class IssueWizardScreen extends StatefulWidget {
  static const routeName = "/issuewizard";

  final String id;
  const IssueWizardScreen({Key key, @required this.id}) : super(key: key);

  @override
  _IssueWizardScreenState createState() => _IssueWizardScreenState();
}

class _IssueWizardScreenState extends State<IssueWizardScreen> {
  int _activeItem = 0;
  bool _showIntro = true;
  bool _showSuccess = false;

  final GlobalKey _scrollviewKey = GlobalKey();
  final ScrollController _controller = ScrollController();

  Widget _buildCollapsible(BuildContext context, GlobalKey key, String header, String body) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
      child: Collapsible(
        header: header,
        onExpansionChanged: (v) => {if (v) jumpToCollapsable(_controller, _scrollviewKey, key)},
        content: SizedBox(width: double.infinity, child: IrmaMarkdown(body)),
        key: key,
      ),
    );
  }

  Widget _buildIntro(BuildContext context, TranslatedValue intro, List<IssueWizardQA> questions) {
    final _collapsableKeys = List<GlobalKey>.generate(questions.length, (int index) => GlobalKey());
    final lang = FlutterI18n.currentLocale(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(
            IrmaTheme.of(context).defaultSpacing,
            0,
            IrmaTheme.of(context).defaultSpacing,
            IrmaTheme.of(context).defaultSpacing,
          ),
          child: IrmaMarkdown(intro.translate(lang)),
        ),
        ...questions.asMap().entries.map(
              (q) => _buildCollapsible(
                context,
                _collapsableKeys[q.key],
                q.value.question.translate(lang),
                q.value.answer.translate(lang),
              ),
            )
      ],
    );
  }

  Widget _buildIntroButtons() {
    return IrmaBottomBar(
      primaryButtonLabel: FlutterI18n.translate(context, "issue_wizard.add"),
      onPrimaryPressed: () => setState(() => _showIntro = false),
      secondaryButtonLabel: FlutterI18n.translate(context, "issue_wizard.back"),
      onSecondaryPressed: () => popToWallet(context),
    );
  }

  Widget _buildWizard(
    BuildContext context,
    TranslatedValue intro,
    TranslatedValue successHeader,
    TranslatedValue successText,
    List<ProgressingListItem> contents,
  ) {
    assert((successHeader == null) == (successText == null),
        "Either specify both successHeader and successText, or neither.");
    final lang = FlutterI18n.currentLocale(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (intro != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: IrmaMarkdown(intro.translate(lang)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: ProgressingList(data: contents, activeItem: activeItem(contents)),
        ),
        if (_showSuccess)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(successHeader.translate(lang), style: Theme.of(context).textTheme.headline3),
          ),
        if (_showSuccess)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: IrmaMarkdown(successText.translate(lang)),
          ),
      ],
    );
  }

  Widget _buildWizardButtons(List<ProgressingListItem> contents, {bool successMessage}) {
    final idx = activeItem(contents);
    return IrmaBottomBar(
      primaryButtonLabel:
          _showSuccess ? FlutterI18n.translate(context, "issue_wizard.done") : contents[idx].buttonLabel,
      onPrimaryPressed: () => next(contents, successMessage: successMessage),
    );
  }

  int activeItem(List<ProgressingListItem> contents) =>
      max(_activeItem, contents.indexWhere((item) => !item.completed));

  void next(List<ProgressingListItem> contents, {bool successMessage}) {
    final nextIdx = contents.indexWhere((item) => !item.completed, activeItem(contents) + 1);
    if (nextIdx == -1) {
      if (!successMessage || _showSuccess) {
        popToWallet(context);
      } else {
        setState(() {
          _activeItem = contents.length + 1;
          _showSuccess = true;
        });
      }
      return;
    }

    setState(() {
      _activeItem = nextIdx;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context).languageCode;
    return StreamBuilder(
      stream: IrmaRepository.get().getIssueWizard().where((event) => event.wizard.id == widget.id),
      builder: (context, AsyncSnapshot<IssueWizardEvent> snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        final wizard = snapshot.data.wizard;
        final logoFile = File(wizard.logoPath ?? "");
        final contents = snapshot.data.wizardContents
            .map(
              (item) => ProgressingListItem(
                header: item.header.translate(lang),
                text: item.text.translate(lang),
                completed: item.completed,
                buttonLabel: item.label?.translate(lang) ??
                    FlutterI18n.translate(
                      context,
                      "issue_wizard.add_credential",
                      translationParams: {"credential": item.header.translate(lang)},
                    ),
              ),
            )
            .toList();

        return Scaffold(
          appBar: IrmaAppBar(
            title: Text(FlutterI18n.translate(context, "issue_wizard.add_cards")),
            leadingAction: () => Navigator.of(context).pop(),
            leadingIcon: Icon(Icons.arrow_back, semanticLabel: FlutterI18n.translate(context, "accessibility.back")),
          ),
          bottomNavigationBar: _showIntro
              ? _buildIntroButtons()
              : _buildWizardButtons(contents, successMessage: wizard.successHeader != null),
          body: SingleChildScrollView(
            controller: _controller,
            key: _scrollviewKey,
            child: Column(
              children: <Widget>[
                LogoBanner(
                  logo: logoFile.existsSync()
                      ? Image.file(logoFile, excludeFromSemantics: true)
                      : Image.asset("assets/non-free/irmalogo.png", excludeFromSemantics: true),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Heading(wizard.title.translate(lang), style: Theme.of(context).textTheme.headline5),
                    ),
                    if (_showIntro)
                      _buildIntro(context, wizard.info, wizard.faq)
                    else
                      _buildWizard(context, wizard.intro, wizard.successHeader, wizard.successText, contents),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
