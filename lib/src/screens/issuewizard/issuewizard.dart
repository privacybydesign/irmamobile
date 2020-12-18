import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
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

  @override
  _IssueWizardScreenState createState() => _IssueWizardScreenState();
}

class QuestionAnswer {
  final String question;
  final String answer;

  QuestionAnswer(this.question, this.answer);
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

  Widget _buildIntro(BuildContext context, String intro, List<QuestionAnswer> questions) {
    final List<GlobalKey> _collapsableKeys = List<GlobalKey>.generate(questions.length, (int index) => GlobalKey());

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
          child: IrmaMarkdown(intro),
        ),
        ...questions.asMap().entries.map(
              (q) => _buildCollapsible(
                context,
                _collapsableKeys[q.key],
                q.value.question,
                q.value.answer,
              ),
            )
      ],
    );
  }

  Widget _buildIntroButtons() {
    return IrmaBottomBar(
      primaryButtonLabel: "Ophalen",
      onPrimaryPressed: () => setState(() => showIntro = false),
      secondaryButtonLabel: "Annuleren",
      onSecondaryPressed: () => popToWallet(context),
    );
  }

  Widget _buildWizard(
    BuildContext context,
    String intro,
    String successHeader,
    String successText,
    List<ProgressingListItem> data,
  ) {
    assert((successHeader == null) == (successText == null),
        "Either specify both successHeader and successText, or neither.");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (intro != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: IrmaMarkdown(intro),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: ProgressingList(data: data, activeItem: activeItem),
        ),
        if (successHeader != null && activeItem == data.length)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(successHeader, style: Theme.of(context).textTheme.headline3),
          ),
        if (successText != null && activeItem == data.length)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: IrmaMarkdown(successText),
          ),
      ],
    );
  }

  Widget _buildWizardButtons(List<ProgressingListItem> wizardData, bool showSuccessMessage) {
    return IrmaBottomBar(
        primaryButtonLabel: activeItem == wizardData.length
            ? "OK"
            : wizardData[activeItem].buttonLabel ?? "Haal ${wizardData[activeItem].header} op",
        onPrimaryPressed: () => setState(() {
              activeItem = (activeItem + 1) % (showSuccessMessage ? wizardData.length + 1 : wizardData.length);
            }));
  }

  @override
  Widget build(BuildContext context) {
    const introIntro =
        """Je moet je kenbaar maken voor het gebruik van Ivido. Hiervoor haal je nu eerst je gegevens op in IRMA.

## Wat is Ivido PGO?
Ivido is je Persoonlijke Gezondheidsomgeving (PGO) waar je al je gegevens over jouw gezondheid kunt opslaan en delen met jouw zorgnetwerk. Een omgeving met begrijpelijke informatie en relevante applicaties, die een leven lang meegaat. Je gebruikt IRMA om je te registreren en om in te loggen bij Ivido PGO.""";
    final introQuestions = [
      QuestionAnswer(
        "Waar haal ik de gegevens op?",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla nibh ante, mollis id neque at, imperdiet egestas nulla. In hac habitasse platea dictumst. Pellentesque risus diam, maximus eget lorem id, suscipit vulputate risus.",
      ),
      QuestionAnswer(
        "Welke gegevens ontvang ik?",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla nibh ante, mollis id neque at, imperdiet egestas nulla. In hac habitasse platea dictumst. Pellentesque risus diam, maximus eget lorem id, suscipit vulputate risus.",
      ),
      QuestionAnswer(
        "Wat heb ik hiervoor nodig?",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla nibh ante, mollis id neque at, imperdiet egestas nulla. In hac habitasse platea dictumst. Pellentesque risus diam, maximus eget lorem id, suscipit vulputate risus.",
      ),
    ];

    final wizardData = [
      ProgressingListItem(
          header: "Persoonsgegevens",
          text:
              "Haal je persoonsgegevens op uit het gemeentelijk register. Je hebt deze gegevens nodig om te laten zien wie je bent. Je logt in met DigiD bij de gemeente Nijmegen die dit voor heel Nederland aanbiedt."),
      ProgressingListItem(
          header: "AGB-code", text: "Haal je AGB-code op van Nuts. Hiermee kun je laten zien dat je in de zorg werkt."),
      ProgressingListItem(
          header: "Log in bij Ivido",
          buttonLabel: "Log in bij Ivido",
          text: "Registreer je bij Ivido door je gegevens te tonen."),
    ];
    const wizardIntro = "Doorloop eenmalig onderstaande stappen om toegang tot Ivido PGO te krijgen.";
    const wizardSuccessHeader = "Gelukt!";
    const wizardSuccessText =
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla nibh ante, mollis id neque at, imperdiet egestas nulla. In hac habitasse platea dictumst. Pellentesque risus diam, maximus eget lorem id, suscipit vulputate risus.";
    // const String wizardSuccessHeader = null;
    // const String wizardSuccessText = null;

    const header = "Ivido PGO";
    const logoPath = "assets/non-free/irmalogo.png";

    return Scaffold(
      appBar: IrmaAppBar(
        title: const Text('Kaartjes ophalen'),
        leadingAction: () => Navigator.of(context).pop(),
        leadingIcon: Icon(Icons.arrow_back, semanticLabel: FlutterI18n.translate(context, "accessibility.back")),
      ),
      bottomNavigationBar:
          showIntro ? _buildIntroButtons() : _buildWizardButtons(wizardData, wizardSuccessHeader != null),
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
                  child: Heading(header, style: Theme.of(context).textTheme.headline5),
                ),
                if (showIntro)
                  _buildIntro(context, introIntro, introQuestions)
                else
                  _buildWizard(context, wizardIntro, wizardSuccessHeader, wizardSuccessText, wizardData),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
