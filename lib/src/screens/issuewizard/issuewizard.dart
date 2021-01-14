import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:irmamobile/src/models/wizard.dart';
import 'package:irmamobile/src/screens/issuewizard/widgets/progressing_list.dart';
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
  int activeItem = 0;
  bool showIntro = true;

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
      onPrimaryPressed: () => setState(() => showIntro = false),
      secondaryButtonLabel: FlutterI18n.translate(context, "issue_wizard.back"),
      onSecondaryPressed: () => popToWallet(context),
    );
  }

  Widget _buildWizard(
    BuildContext context,
    TranslatedValue intro,
    TranslatedValue successHeader,
    TranslatedValue successText,
    List<ProgressingListItem> data,
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
          child: ProgressingList(data: data, activeItem: activeItem),
        ),
        if (successHeader != null && activeItem == data.length)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(successHeader.translate(lang), style: Theme.of(context).textTheme.headline3),
          ),
        if (successText != null && activeItem == data.length)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: IrmaMarkdown(successText.translate(lang)),
          ),
      ],
    );
  }

  Widget _buildWizardButtons(ProgressingListItem item, int count, bool showSuccessMessage) {
    return IrmaBottomBar(
      primaryButtonLabel: item?.buttonLabel ?? FlutterI18n.translate(context, "issue_wizard.done"),
      onPrimaryPressed: () => setState(() {
        activeItem = (activeItem + 1) % (showSuccessMessage ? count + 1 : count);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    const logoPath = "assets/non-free/irmalogo.png";
    final lang = FlutterI18n.currentLocale(context).languageCode;

    return StreamBuilder(
      stream: IrmaRepository.get().getIssueWizard().where((event) => event.wizard.id == widget.id),
      builder: (context, AsyncSnapshot<IssueWizardEvent> snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        final wizard = snapshot.data.wizard;
        final contents = snapshot.data.wizardContents
            .map(
              (item) => ProgressingListItem(
                header: item.header.translate(lang),
                text: item.text.translate(lang),
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
          bottomNavigationBar: showIntro
              ? _buildIntroButtons()
              : _buildWizardButtons(
                  activeItem < contents.length ? contents[activeItem] : null,
                  contents.length,
                  wizard.successHeader != null,
                ),
          body: SingleChildScrollView(
            controller: _controller,
            key: _scrollviewKey,
            child: Column(
              children: <Widget>[
                LogoBanner(logo: Image.asset(logoPath, excludeFromSemantics: true)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Heading(wizard.title.translate(lang), style: Theme.of(context).textTheme.headline5),
                    ),
                    if (showIntro)
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
